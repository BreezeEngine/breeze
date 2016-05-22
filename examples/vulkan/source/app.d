import std.stdio;
import erupted;

void enforceVk(VkResult res){
	import std.exception;
	import std.conv;
	enforce(res is VkResult.VK_SUCCESS, res.to!string);
}
void main()
{
	import std.exception;
	import derelict.sdl2.sdl;
	import std.algorithm.searching;
	import std.algorithm.iteration;
	import core.stdc.string;

	DerelictSDL2.load();
	auto sdlWindow = SDL_CreateWindow("vulkan", 0, 0, 800, 600, 0);
	SDL_SysWMinfo sdlWindowInfo;

	SDL_VERSION(&sdlWindowInfo.version_);
	enforce(SDL_GetWindowWMInfo(sdlWindow, &sdlWindowInfo), "sdl err");
	writeln(sdlWindowInfo.subsystem);

	DerelictErupted.load();
	VkApplicationInfo appinfo;
	appinfo.pApplicationName = "Breeze";
	appinfo.apiVersion = VK_MAKE_VERSION(1, 0, 2);
	
	import std.container.array;
	const(char*)[2] extensionNames = [
		"VK_KHR_surface",
		"VK_KHR_xlib_surface",
	];
	uint extensionCount = 0;
	vkEnumerateInstanceExtensionProperties(null, &extensionCount, null );
	writeln("cou ", extensionCount);

	auto extensionProps = new VkExtensionProperties[](extensionCount);
	vkEnumerateInstanceExtensionProperties(null, &extensionCount, extensionProps.ptr );
	foreach(extension; extensionProps){
		writeln(extension.extensionName);
	}

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

	VkInstance instance;
	enforceVk(vkCreateInstance(&createinfo, null, &instance));
	//DVulkanLoader.loadAllFunctions(instance);
	loadInstanceLevelFunctions(instance);
	//EruptedLoader.loadAllFunctions(instance);


	auto xlibInfo = VkXlibSurfaceCreateInfoKHR(
		VkStructureType.VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR,
		null,
		0,
		sdlWindowInfo.info.x11.display,
		sdlWindowInfo.info.x11.window
	);
	//vkCreateXcbSurfaceKHR();
	VkSurfaceKHR surface;
	enforceVk(vkCreateXlibSurfaceKHR(instance, &xlibInfo, null, &surface));

	uint numOfDevices;
	enforceVk(vkEnumeratePhysicalDevices(instance, &numOfDevices, null));

	auto devices = new VkPhysicalDevice[](numOfDevices);
	enforceVk(vkEnumeratePhysicalDevices(instance, &numOfDevices, devices.ptr));

	VkPhysicalDevice physicalDevice = null;

	const(char*)[1] deviceExtensions = ["VK_KHR_swapchain"];

	size_t queueFamilyIndex = 0;
	foreach(index, device; devices){
		VkPhysicalDeviceProperties props;

		vkGetPhysicalDeviceProperties(device, &props);
		if(props.deviceType is VkPhysicalDeviceType.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU){
			uint queueCount = 0;
			vkGetPhysicalDeviceQueueFamilyProperties(device, &queueCount, null);
			enforce(queueCount > 0);
			auto queueFamilyProp = new VkQueueFamilyProperties[](queueCount);
			vkGetPhysicalDeviceQueueFamilyProperties(device, &queueCount, queueFamilyProp.ptr);
			foreach(familyIndex,  prop; queueFamilyProp){
				if(prop.queueCount > 0 && (prop.queueFlags & VkQueueFlagBits.VK_QUEUE_GRAPHICS_BIT)){
					queueFamilyIndex = familyIndex;
					physicalDevice = device;
				}
			}
		}
	}

	uint extensionDeviceCount = 0;
	vkEnumerateDeviceExtensionProperties(physicalDevice, null, &extensionDeviceCount, null);
	auto extensionDeviceProps = new VkExtensionProperties[](extensionDeviceCount);

	vkEnumerateDeviceExtensionProperties(physicalDevice, null, &extensionDeviceCount, extensionDeviceProps.ptr);

	enforce(physicalDevice != null, "Device is null");
	//enforce the swapchain
	enforce(extensionDeviceProps[].map!(prop => prop.extensionName).count!((name){
				return strcmp(cast(const(char*))name, "VK_KHR_swapchain" ) == 0;
	}) > 0);

	float[1] priorities = [1.0f];
	VkDeviceQueueCreateInfo deviceQueueInfo = 
		VkDeviceQueueCreateInfo(
			VkStructureType.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			null,
			0,
			cast(uint)queueFamilyIndex,
			cast(uint)priorities.length,
			priorities.ptr

		);
	auto deviceInfo = VkDeviceCreateInfo(
		VkStructureType.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		null,
		0,
		1,
		&deviceQueueInfo,
		0,
		null,
		cast(uint)deviceExtensions.length,
		deviceExtensions.ptr,
		null
	);
	VkDevice device;
	enforceVk(vkCreateDevice(physicalDevice, &deviceInfo, null, &device));

	loadDeviceLevelFunctions(device);
	VkQueue queue;
	vkGetDeviceQueue(device, cast(uint)queueFamilyIndex, 0, &queue);


}
