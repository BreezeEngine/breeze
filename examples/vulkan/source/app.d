import std.stdio;
import erupted;

void enforceVk(VkResult res){
	import std.exception;
	import std.conv;
	enforce(res is VkResult.VK_SUCCESS, res.to!string);
}
VkBool32 MyDebugReportCallback(
    VkDebugReportFlagsEXT       flags,
    VkDebugReportObjectTypeEXT  objectType,
    uint64_t                    object,
    size_t                      location,
    int32_t                     messageCode,
    const char*                 pLayerPrefix,
    const char*                 pMessage,
    void*                       pUserData)
{
	return VK_FALSE;
}

struct VkContext{
	VkInstance instance;
	VkSurfaceKHR surface;
	VkPhysicalDevice physicalDevice;
	VkDevice logicalDevice;
	ulong presentQueueFamilyIndex = -1;
	VkQueue graphicsQueue;
	VkQueue presentQueue;
}
void main()
{
	import std.exception;
	import derelict.sdl2.sdl;
	import std.algorithm.searching;
	import std.algorithm.iteration;
	import core.stdc.string;

	VkContext vkcontext;

	DerelictSDL2.load();
	auto sdlWindow = SDL_CreateWindow("vulkan", 0, 0, 800, 600, 0);
	SDL_SysWMinfo sdlWindowInfo;

	SDL_VERSION(&sdlWindowInfo.version_);
	enforce(SDL_GetWindowWMInfo(sdlWindow, &sdlWindowInfo), "sdl err");

	DerelictErupted.load();
	VkApplicationInfo appinfo;
	appinfo.pApplicationName = "Breeze";
	appinfo.apiVersion = VK_MAKE_VERSION(1, 0, 2);
	
	const(char*)[3] extensionNames = [
		"VK_KHR_surface",
		"VK_KHR_xlib_surface",
		"VK_EXT_debug_report"
	];
	uint extensionCount = 0;
	vkEnumerateInstanceExtensionProperties(null, &extensionCount, null );

	auto extensionProps = new VkExtensionProperties[](extensionCount);
	vkEnumerateInstanceExtensionProperties(null, &extensionCount, extensionProps.ptr );

	enforce(extensionNames[].all!((extensionName){
		return extensionProps[].count!((extension){
			return strcmp(cast(const(char*))extension.extensionName, extensionName) == 0;
		}) > 0;
	}), "extension props failure");

	uint layerCount = 0;
	vkEnumerateInstanceLayerProperties(&layerCount, null);

	auto layerProps = new VkLayerProperties[](layerCount);
	vkEnumerateInstanceLayerProperties(&layerCount, layerProps.ptr);

	const(char*)[1] validationLayers = ["VK_LAYER_LUNARG_standard_validation"];

	enforce(validationLayers[].all!((layerName){
		return layerProps[].count!((layer){
			return strcmp(cast(const(char*))layer.layerName, layerName) == 0;
		}) > 0;
	}), "Validation layer failure");

	VkInstanceCreateInfo createinfo;
	createinfo.sType = VkStructureType.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
	createinfo.pApplicationInfo = &appinfo;
	createinfo.enabledExtensionCount = cast(uint)extensionNames.length;
	createinfo.ppEnabledExtensionNames = extensionNames.ptr;
	createinfo.enabledLayerCount = validationLayers.length;
	createinfo.ppEnabledLayerNames = validationLayers.ptr;

	enforceVk(vkCreateInstance(&createinfo, null, &vkcontext.instance));
	//uint function(uint flags, VkDebugReportObjectTypeEXT objectType, ulong object, ulong location, int messageCode, const(char*) pLayerPrefix, const(char*) pMessage, void* pUserData)

	loadInstanceLevelFunctions(vkcontext.instance);
	//auto debugcallbackCreateInfo = VkDebugReportCallbackCreateInfoEXT(
	//	VkStructureType.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
	//	null,
	//	VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_ERROR_BIT_EXT,
	//	&MyDebugReportCallback,
	//	null
	//);

	auto xlibInfo = VkXlibSurfaceCreateInfoKHR(
		VkStructureType.VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
		null,
		0,
		sdlWindowInfo.info.x11.display,
		sdlWindowInfo.info.x11.window
	);
	//vkCreateXcbSurfaceKHR();
	enforceVk(vkCreateXlibSurfaceKHR(vkcontext.instance, &xlibInfo, null, &vkcontext.surface));

	uint numOfDevices;
	enforceVk(vkEnumeratePhysicalDevices(vkcontext.instance, &numOfDevices, null));

	auto devices = new VkPhysicalDevice[](numOfDevices);
	enforceVk(vkEnumeratePhysicalDevices(vkcontext.instance, &numOfDevices, devices.ptr));

	const(char*)[1] deviceExtensions = ["VK_KHR_swapchain"];

	foreach(index, device; devices){
		VkPhysicalDeviceProperties props;

		vkGetPhysicalDeviceProperties(device, &props);
		if(props.deviceType is VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU){
			uint queueCount = 0;
			vkGetPhysicalDeviceQueueFamilyProperties(device, &queueCount, null);
			enforce(queueCount > 0);
			auto queueFamilyProp = new VkQueueFamilyProperties[](queueCount);
			vkGetPhysicalDeviceQueueFamilyProperties(device, &queueCount, queueFamilyProp.ptr);

			auto presentIndex = queueFamilyProp[].countUntil!((prop){
				return prop.queueCount > 0 && (prop.queueFlags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT);
			});

			VkBool32 supportsPresent;
      vkGetPhysicalDeviceSurfaceSupportKHR(
				device, cast(uint)presentIndex,
				vkcontext.surface, &supportsPresent
			);

			if(presentIndex !is -1 && supportsPresent){
				vkcontext.presentQueueFamilyIndex = presentIndex;
				vkcontext.physicalDevice = device;
				break;
			}
		}
	}

	enforce(
		vkcontext.presentQueueFamilyIndex !is -1 &&
		vkcontext.physicalDevice,
		"Could not find a suitable device"
	);

	uint extensionDeviceCount = 0;
	vkEnumerateDeviceExtensionProperties(vkcontext.physicalDevice, null, &extensionDeviceCount, null);
	auto extensionDeviceProps = new VkExtensionProperties[](extensionDeviceCount);

	vkEnumerateDeviceExtensionProperties(vkcontext.physicalDevice, null, &extensionDeviceCount, extensionDeviceProps.ptr);

	enforce(vkcontext.physicalDevice != null, "Device is null");
	//enforce the swapchain
	enforce(extensionDeviceProps[].map!(prop => prop.extensionName).count!((name){
				return strcmp(cast(const(char*))name, "VK_KHR_swapchain" ) == 0;
	}) > 0);

	float[1] priorities = [1.0f];
	VkDeviceQueueCreateInfo deviceQueueCreateInfo =
		VkDeviceQueueCreateInfo(
			VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			null,
			0,
			cast(uint)vkcontext.presentQueueFamilyIndex,
			cast(uint)priorities.length,
			priorities.ptr
	);

	auto deviceInfo = VkDeviceCreateInfo(
		VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		null,
		0,
		1,
		&deviceQueueCreateInfo,
		0,
		null,
		cast(uint)deviceExtensions.length,
		deviceExtensions.ptr,
		null
	);
	enforceVk(vkCreateDevice(vkcontext.physicalDevice, &deviceInfo, null, &vkcontext.logicalDevice));

	loadDeviceLevelFunctions(vkcontext.logicalDevice);
	VkQueue queue;
	vkGetDeviceQueue(vkcontext.logicalDevice, cast(uint)vkcontext.presentQueueFamilyIndex, 0, &vkcontext.graphicsQueue);
}
