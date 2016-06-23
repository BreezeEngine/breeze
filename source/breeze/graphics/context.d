module breeze.graphics.context;

import erupted;
import std.stdio;
import option;
import breeze.util.array;

void enforceVk(VkResult res){
  import std.exception;
  import std.conv;
  enforce(res is VkResult.VK_SUCCESS, res.to!string);
}
struct Version{}

struct PhysicalDeviceInfos{}

enum InstanceExtension{
    khrSurface = "VK_KHR_surface",
    khrDisplay = "VK_KHR_display",
    khrXlibSurface = "VK_KHR_XLIB_SURFACE",
}
struct ApplicationInfo{
    string applicationName;
    Version applicationVersion;
    string engineName;
    Version engineVersion;
}

struct PhysicalDevice{
    VkPhysicalDevice handle;
}

struct DeviceIndex{
    PhysicalDevice device;
    ulong graphicsQueueIndex;
    ulong presentQueueIndex;
}

struct Instance{
    VkInstance handle;
}

struct Surface{
    VkSurfaceKHR handle;
}

import derelict.sdl2.sdl;
Surface createSurfaceFromSdl(ref Instance instance, SDL_Window* window){
    import std.exception: enforce;
    SDL_SysWMinfo windowInfo;
    SDL_VERSION(&windowInfo.version_);
    enforce(SDL_GetWindowWMInfo(window, &windowInfo), "sdl err");
    auto xlibInfo = VkXlibSurfaceCreateInfoKHR(
    VkStructureType.VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
    null,
    0,
    windowInfo.info.x11.display,
    windowInfo.info.x11.window
  );
    VkSurfaceKHR vksurface;
    enforceVk(vkCreateXlibSurfaceKHR(instance.handle, &xlibInfo, null, &vksurface));
    return Surface(vksurface);
}
auto findQueueIndex(Flags...)(QueueFamilyProperties[] props, Flags flags){
    import std.algorithm.searching;
    import std.algorithm.iteration;
    import std.range;
    auto filtered = props[].enumerate!ulong(0).filter!((prop){
        return prop.value.supports(flags);
    });
    if(filtered.empty){
        return none!(ulong);
    }
    auto seperateQueueFamily = filtered.filter!((prop){
        import breeze.meta;
        return prop.value.queueFlags is logicalOr!uint(flags);
    });
    if(!seperateQueueFamily.empty){
        return some(seperateQueueFamily.front.index);
    }
    return some(filtered.front.index);
}
auto findQueuePresentIndex(ref PhysicalDevice device, QueueFamilyProperties[] props, Surface surface){
    import std.algorithm.searching;
    import std.range: iota;
    long index = iota(0, props.length).countUntil!((index){
        uint isPresent;
        vkGetPhysicalDeviceSurfaceSupportKHR(
            device.handle,
            cast(uint)index,
            surface.handle,
            &isPresent
        );
        return isPresent > 0;
    });
    if(index is -1){
        return none!(ulong);
    }
    else{
        return some(cast(ulong)index);
    }
}

struct DeviceQueueInfo{
    PhysicalDevice device;
    ulong graphicFamilyIndex;
    ulong presentFamilyIndex;
    ulong transferFamilyIndex;
    ulong computeFamilyIndex;
}

auto findCapableDevices(PhysicalDevice[] devices, ref Surface surface){
    import std.algorithm.iteration: map, filter;
    return devices.map!((device){
        if(!device.getProperties().deviceType is PhysicalDeviceType.descreteGpu){
            return none!DeviceQueueInfo();
        }
        auto props = device.queueFamilyProperties;
        auto graphicIndex = findQueueIndex(props[], QueueFlags.graphics);
        auto computeIndex = findQueueIndex(props[], QueueFlags.compute);
        auto transferIndex = findQueueIndex(props[], QueueFlags.transfer);
        auto presentIndex = findQueuePresentIndex(device, props[], surface);
        if(graphicIndex.isNone ||
           presentIndex.isNone ||
           transferIndex.isNone ||
           computeIndex.isNone){
            return none!DeviceQueueInfo;
        }
        return some(
            DeviceQueueInfo(
                device,
                graphicIndex.get,
                presentIndex.get,
                computeIndex.get,
                transferIndex.get
            )
        );
    })
    .filter!(device => device.isSome)
    .map!(device => device.get);
}
Array!PhysicalDevice physicalDevices(ref Instance instance){
    import std.algorithm.mutation: copy;
    import std.algorithm.iteration: map;
    uint numOfDevices;
    enforceVk(vkEnumeratePhysicalDevices(instance.handle, &numOfDevices, null));
    auto vkdevices = Array!VkPhysicalDevice(numOfDevices);
    enforceVk(vkEnumeratePhysicalDevices(instance.handle, &numOfDevices, vkdevices.ptr));
    auto devices = Array!PhysicalDevice(numOfDevices);
    vkdevices[].map!(d => PhysicalDevice(d)).copy(devices[]);
    return devices;
}

PhysicalDeviceProperties getProperties(ref PhysicalDevice device){
    VkPhysicalDeviceProperties props;
    vkGetPhysicalDeviceProperties(device.handle, &props);
    import std.string;
    return PhysicalDeviceProperties(
        props.apiVersion,
        props.driverVersion,
        props.vendorID,
        props.deviceID,
        cast(PhysicalDeviceType)props.deviceType,
        fromStringz(props.deviceName.ptr).idup,
        props.pipelineCacheUUID,
        props.limits,
        props.sparseProperties
    );
}

enum PhysicalDeviceType {
	other = 0,
	integratedGpu = 1,
	descreteGpu = 2,
	virtualGpu = 3,
	cpu  = 4,
}

struct PhysicalDeviceProperties {
    uint                                apiVersion;
    uint                                driverVersion;
    uint                                vendorID;
    uint                                deviceID;
    PhysicalDeviceType                  deviceType;
    string                              deviceName;
    ubyte[VK_UUID_SIZE]               pipelineCacheUUID;
    VkPhysicalDeviceLimits              limits;
    VkPhysicalDeviceSparseProperties    sparseProperties;
}

bool supports(Flags...)(ref QueueFamilyProperties  props, Flags flags){
    bool result = true;
    foreach(flag; flags){
        result = result && (flag & props.queueFlags);
    }
    return result;
}
enum QueueFlags {
    graphics = 0x00000001,
    compute = 0x00000002,
    transfer = 0x00000004,
    sparseBinding = 0x00000008,
}

struct Extent3D {
    uint  width;
    uint  height;
    uint  depth;
}
struct QueueFamilyProperties {
    uint  queueFlags;
    uint      queueCount;
    uint      timestampValidBits;
    Extent3D    minImageTransferGranularity;
}

auto queueFamilyProperties(PhysicalDevice device){
    import std.algorithm.mutation: copy;
    import std.algorithm.iteration: map;
    uint queueCount = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(device.handle, &queueCount, null);
    auto vkQueueFamilyProp = Array!VkQueueFamilyProperties(queueCount);
    vkGetPhysicalDeviceQueueFamilyProperties(device.handle, &queueCount, vkQueueFamilyProp.ptr);
    import std.experimental.allocator.gc_allocator;
    auto queueFamilyProp = Array!(QueueFamilyProperties)(queueCount);

    vkQueueFamilyProp[].map!((ref prop){
        return QueueFamilyProperties(
            cast(uint)prop.queueFlags,
            prop.queueCount,
            prop.timestampValidBits,
            cast(Extent3D)prop.minImageTransferGranularity
        );
    }).copy(queueFamilyProp[]);
    return queueFamilyProp;
}

Instance createInstance(
    string appName,
    uint apiVersion,
    string[] extensions,
    string[] validationLayers){

    import std.exception: enforce;
    import std.algorithm.searching: all;
    import std.algorithm.iteration;
    DerelictErupted.load();
    VkApplicationInfo appinfo;
    appinfo.pApplicationName = appName.ptr;
    appinfo.apiVersion = apiVersion;
    VkInstance vkinstance;

    import std.string;
    import std.algorithm.mutation;
    import breeze.util.array;
    //Array!(immutable char*) cext;
    auto cext = Array!(immutable(char)*)(extensions.length);
    extensions.map!(s => s.toStringz).copy(cext[]);

    auto cval = Array!(immutable(char)*)(validationLayers.length);
    validationLayers.map!(s => s.toStringz).copy(cval[]);

    uint extensionCount = 0;
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, null );

    auto extensionProps = Array!VkExtensionProperties(extensionCount);
    vkEnumerateInstanceExtensionProperties(null, &extensionCount, extensionProps.ptr );

    uint layerCount = 0;
    vkEnumerateInstanceLayerProperties(&layerCount, null);

    auto layerProps = Array!VkLayerProperties(layerCount);
    vkEnumerateInstanceLayerProperties(&layerCount, layerProps.ptr);

    import std.algorithm.searching: count;
    import core.stdc.string;

    enforce(validationLayers[].all!((layerName){
      return layerProps[].count!((layer){
        return strcmp(cast(const(char*))layer.layerName, layerName.ptr) == 0;
      }) > 0;
    }), "");

    VkInstanceCreateInfo createinfo;
    createinfo.sType = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    createinfo.pApplicationInfo = &appinfo;
    createinfo.enabledExtensionCount = cast(uint)extensions.length;
    createinfo.ppEnabledExtensionNames = cext.ptr;
    createinfo.enabledLayerCount = cast(uint)validationLayers.length;
    createinfo.ppEnabledLayerNames = cval.ptr;

    enforceVk(vkCreateInstance(&createinfo, null, &vkinstance));
    loadInstanceLevelFunctions(vkinstance);

    Instance instance = {
      handle: vkinstance,
    };
    return instance;
}

struct Device{
    VkDevice handle;
}

Device createDevice(DeviceQueueInfo deviceQueueInfo,
                    string[] deviceExtensions,
                    string[] validationLayers){
    import std.algorithm.iteration: uniq;
    import std.algorithm.searching: count;
    import std.range;
    VkDevice vkdevice;
    ulong[4] familyIndices = [
        deviceQueueInfo.computeFamilyIndex,
        deviceQueueInfo.graphicFamilyIndex,
        deviceQueueInfo.transferFamilyIndex,
        deviceQueueInfo.presentFamilyIndex,
    ];
    VkPhysicalDeviceFeatures features;
    features.shaderClipDistance = VK_TRUE;
    auto uniqueFamilyIndicies = familyIndices[].uniq;
    auto indexLength = uniqueFamilyIndicies.count;
    auto createInfos = Array!VkDeviceQueueCreateInfo(indexLength);
    auto priorities = Array!float(1);
    foreach(ref priority; priorities){
        priority = 1.0f;
    }
    foreach(index, familyIndex; uniqueFamilyIndicies.enumerate(0)){
          createInfos[index] = (VkDeviceQueueCreateInfo(
              VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
              null,
              0,
              cast(uint)familyIndex,
              cast(uint)priorities.length,
              priorities.ptr
          ));
    }
    import std.string;
    import std.algorithm.mutation;
    import std.algorithm.iteration;
    auto cext = Array!(immutable(char)*)(deviceExtensions.length);
    deviceExtensions.map!(s => s.toStringz).copy(cext[]);

    auto cval = Array!(immutable(char)*)(validationLayers.length);
    validationLayers.map!(s => s.toStringz).copy(cval[]);
    auto deviceInfo = VkDeviceCreateInfo(
      VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      null,
      0,
      1,
      createInfos.ptr,
      cast(uint)cval.length,
      cval.ptr,
      cast(uint)cext.length,
      cext.ptr,
      &features
    );
    enforceVk(
        vkCreateDevice(
            deviceQueueInfo.device.handle,
            &deviceInfo,
            null,
            &vkdevice
        )
    );

  return Device(vkdevice);
}
