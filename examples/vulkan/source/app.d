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
    void*                       pUserData) nothrow @nogc
{
	import std.range;
	import std.string;
	//printf("Debug: \n");
	//printf("\n");
	return VK_FALSE;
}

struct VkContext{
	VkInstance instance;
	VkSurfaceKHR surface;
	VkPhysicalDevice physicalDevice;
	VkDevice logicalDevice;
	ulong presentQueueFamilyIndex = -1;
	VkQueue presentQueue;
	uint width = -1;
	uint height = -1;
	VkSwapchainKHR swapchain;
	VkCommandBuffer setupCmdBuffer;
	VkCommandBuffer drawCmdBuffer;
	VkImage[] presentImages;
	VkImage depthImage;
	VkPhysicalDeviceMemoryProperties memoryProperties;
}
void main()
{
	import std.exception;
	import derelict.sdl2.sdl;
	import std.algorithm.searching;
	import std.algorithm.iteration;
	import core.stdc.string;

	VkContext vkcontext;
	vkcontext.width = 800;
	vkcontext.height = 600;

	DerelictSDL2.load();
	auto sdlWindow = SDL_CreateWindow("vulkan", 0, 0, 800, 600, SDL_WINDOW_OPENGL);
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
	auto debugcallbackCreateInfo = VkDebugReportCallbackCreateInfoEXT(
		VkStructureType.VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
		null,
		VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_ERROR_BIT_EXT |
		VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_INFORMATION_BIT_EXT |
		VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_WARNING_BIT_EXT |
		VkDebugReportFlagBitsEXT.VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT,
		&MyDebugReportCallback,
		null
	);
	VkDebugReportCallbackEXT callback;
	enforceVk(vkCreateDebugReportCallbackEXT(vkcontext.instance, &debugcallbackCreateInfo, null, &callback));

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
		validationLayers.length,
		validationLayers.ptr,
		cast(uint)deviceExtensions.length,
		deviceExtensions.ptr,
		null
	);
	enforceVk(vkCreateDevice(vkcontext.physicalDevice, &deviceInfo, null, &vkcontext.logicalDevice));

	loadDeviceLevelFunctions(vkcontext.logicalDevice);
	VkQueue queue;
	vkGetDeviceQueue(vkcontext.logicalDevice, cast(uint)vkcontext.presentQueueFamilyIndex, 0, &vkcontext.presentQueue);

	uint formatCount = 0;
	vkGetPhysicalDeviceSurfaceFormatsKHR(vkcontext.physicalDevice, vkcontext.surface, &formatCount, null);
	enforce(formatCount > 0, "Format failed");
	auto surfaceFormats = new VkSurfaceFormatKHR[](formatCount);
	vkGetPhysicalDeviceSurfaceFormatsKHR(vkcontext.physicalDevice, vkcontext.surface, &formatCount, surfaceFormats.ptr);

	VkFormat colorFormat;
	if(surfaceFormats[0].format is VK_FORMAT_UNDEFINED){
		colorFormat = VK_FORMAT_B8G8R8_UNORM;
	}
	else{
		colorFormat = surfaceFormats[0].format;
	}

	VkColorSpaceKHR colorSpace;
	colorSpace = surfaceFormats[0].colorSpace;

	VkSurfaceCapabilitiesKHR surfaceCapabilities;
	vkGetPhysicalDeviceSurfaceCapabilitiesKHR(vkcontext.physicalDevice, vkcontext.surface, &surfaceCapabilities);

	uint desiredImageCount = 2;
	if( desiredImageCount < surfaceCapabilities.minImageCount ) {
	    desiredImageCount = surfaceCapabilities.minImageCount;
	}
	else if( surfaceCapabilities.maxImageCount != 0 &&
	         desiredImageCount > surfaceCapabilities.maxImageCount ) {
		desiredImageCount = surfaceCapabilities.maxImageCount;
	}

	VkExtent2D surfaceResolution = surfaceCapabilities.currentExtent;

	if(surfaceResolution.width is -1){
		surfaceResolution.width = vkcontext.width;
		surfaceResolution.height = vkcontext.height;
	}
	else{
		vkcontext.width = surfaceResolution.width;
		vkcontext.height = surfaceResolution.height;
	}

	VkSurfaceTransformFlagBitsKHR preTransform = surfaceCapabilities.currentTransform;
	if(surfaceCapabilities.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR){
		preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
	}

	uint presentModeCount = 0;
	vkGetPhysicalDeviceSurfacePresentModesKHR(vkcontext.physicalDevice, vkcontext.surface, &presentModeCount, null);
	auto presentModes = new VkPresentModeKHR[](presentModeCount);
	vkGetPhysicalDeviceSurfacePresentModesKHR(vkcontext.physicalDevice, vkcontext.surface, &presentModeCount, presentModes.ptr);

	VkPresentModeKHR presentMode = VK_PRESENT_MODE_FIFO_KHR;
	foreach(mode; presentModes){
		if(mode is VK_PRESENT_MODE_MAILBOX_KHR){
			presentMode = mode;
			break;
		}
	}

	VkSwapchainCreateInfoKHR swapchainCreateInfo;
	swapchainCreateInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
	swapchainCreateInfo.surface = vkcontext.surface;
	swapchainCreateInfo.imageFormat = colorFormat;
	swapchainCreateInfo.minImageCount = desiredImageCount;
	swapchainCreateInfo.imageColorSpace = colorSpace;
	swapchainCreateInfo.imageExtent = surfaceResolution;
	swapchainCreateInfo.imageArrayLayers = 1;
	swapchainCreateInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
	swapchainCreateInfo.imageSharingMode = VkSharingMode.VK_SHARING_MODE_EXCLUSIVE;
	swapchainCreateInfo.preTransform = preTransform;
	swapchainCreateInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
	swapchainCreateInfo.presentMode = presentMode;
	swapchainCreateInfo.clipped = VK_TRUE;
	swapchainCreateInfo.oldSwapchain = null;

	enforceVk(vkCreateSwapchainKHR(vkcontext.logicalDevice, &swapchainCreateInfo, null, &vkcontext.swapchain));

	VkCommandPoolCreateInfo commandPoolCreateInfo;
	commandPoolCreateInfo.sType = VkStructureType.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
	commandPoolCreateInfo.flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT;
	commandPoolCreateInfo.queueFamilyIndex = cast(uint)vkcontext.presentQueueFamilyIndex;

	VkCommandPool commandPool;
	enforceVk(vkCreateCommandPool(vkcontext.logicalDevice, &commandPoolCreateInfo, null, &commandPool));

	VkCommandBufferAllocateInfo cmdBufferAllocateInfo;
	cmdBufferAllocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
	cmdBufferAllocateInfo.commandPool = commandPool;
	cmdBufferAllocateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
	cmdBufferAllocateInfo.commandBufferCount = 1;

	enforceVk(vkAllocateCommandBuffers(vkcontext.logicalDevice, &cmdBufferAllocateInfo, &vkcontext.setupCmdBuffer));
	enforceVk(vkAllocateCommandBuffers(vkcontext.logicalDevice, &cmdBufferAllocateInfo, &vkcontext.drawCmdBuffer));


	uint imageCount = 0;
	vkGetSwapchainImagesKHR(vkcontext.logicalDevice, vkcontext.swapchain, &imageCount, null);
	vkcontext.presentImages = new VkImage[](imageCount);
	enforceVk(vkGetSwapchainImagesKHR(vkcontext.logicalDevice, vkcontext.swapchain, &imageCount, vkcontext.presentImages.ptr));

	VkImageViewCreateInfo imgViewCreateInfo;
	imgViewCreateInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
	imgViewCreateInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
	imgViewCreateInfo.format = colorFormat;
	imgViewCreateInfo.components =
		VkComponentMapping(
			VK_COMPONENT_SWIZZLE_R,
			VK_COMPONENT_SWIZZLE_G,
			VK_COMPONENT_SWIZZLE_B,
			VK_COMPONENT_SWIZZLE_A,
	);

	imgViewCreateInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	imgViewCreateInfo.subresourceRange.baseMipLevel = 0;
	imgViewCreateInfo.subresourceRange.levelCount = 1;
	imgViewCreateInfo.subresourceRange.baseArrayLayer = 0;
	imgViewCreateInfo.subresourceRange.layerCount = 1;


	VkCommandBufferBeginInfo beginInfo;
	beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
	beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

	VkFenceCreateInfo fenceCreateInfo;
	fenceCreateInfo.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;

	VkFence submitFence;
	vkCreateFence(vkcontext.logicalDevice, &fenceCreateInfo, null, &submitFence);


	auto presentImageViews = new VkImageView[](imageCount);
	import std.range: iota;
	foreach(index; iota(0, imageCount)){
		imgViewCreateInfo.image = vkcontext.presentImages[index];

		vkBeginCommandBuffer(vkcontext.setupCmdBuffer, &beginInfo);
		VkImageMemoryBarrier layoutTransitionBarrier;
		layoutTransitionBarrier.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
		layoutTransitionBarrier.srcAccessMask = 0;
		layoutTransitionBarrier.dstAccessMask = VK_ACCESS_MEMORY_READ_BIT;
		layoutTransitionBarrier.oldLayout = VK_IMAGE_LAYOUT_UNDEFINED;
		layoutTransitionBarrier.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
		layoutTransitionBarrier.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		layoutTransitionBarrier.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED;
		layoutTransitionBarrier.image = vkcontext.presentImages[index];
		layoutTransitionBarrier.subresourceRange = VkImageSubresourceRange(VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1);

		vkCmdPipelineBarrier(
			vkcontext.setupCmdBuffer,
      VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, 
      VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT, 
      0,
      0, null,
      0, null, 
      1, &layoutTransitionBarrier );

		vkEndCommandBuffer(vkcontext.setupCmdBuffer);

		VkPipelineStageFlags[1] waitStageMesh = [VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT];
		VkSubmitInfo submitInfo;
		submitInfo.waitSemaphoreCount = 0;
		submitInfo.pWaitSemaphores = null;
		submitInfo.pWaitDstStageMask = waitStageMesh.ptr;
		submitInfo.commandBufferCount = 1;
		submitInfo.pCommandBuffers = &vkcontext.setupCmdBuffer;
		submitInfo.signalSemaphoreCount = 0;
		submitInfo.pSignalSemaphores = null;

		enforceVk(vkQueueSubmit(vkcontext.presentQueue, 1, &submitInfo, submitFence));

		vkWaitForFences(vkcontext.logicalDevice, 1, &submitFence, VK_TRUE, ulong.max);
		vkResetFences(vkcontext.logicalDevice, 1, &submitFence);

		vkResetCommandBuffer(vkcontext.setupCmdBuffer, 0);

		enforceVk(vkCreateImageView(vkcontext.logicalDevice, &imgViewCreateInfo, null, &presentImageViews[index]));
	}

	vkGetPhysicalDeviceMemoryProperties(vkcontext.physicalDevice, &vkcontext.memoryProperties);

	VkImageCreateInfo imageCreateInfo;
	imageCreateInfo.imageType = VK_IMAGE_TYPE_2D;
	imageCreateInfo.format = VK_FORMAT_D16_UNORM;
	imageCreateInfo.extent = VkExtent3D(vkcontext.width, vkcontext.height, 1);
	imageCreateInfo.mipLevels = 1;
	imageCreateInfo.arrayLayers = 1;
	imageCreateInfo.samples = VK_SAMPLE_COUNT_1_BIT;
	imageCreateInfo.tiling = VK_IMAGE_TILING_OPTIMAL;
	imageCreateInfo.usage = VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
	imageCreateInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
	imageCreateInfo.queueFamilyIndexCount = 0;
	imageCreateInfo.pQueueFamilyIndices = null;
	imageCreateInfo.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;


	enforceVk(vkCreateImage(vkcontext.logicalDevice, &imageCreateInfo, null, &vkcontext.depthImage));

	VkMemoryRequirements memoryRequirements;
	vkGetImageMemoryRequirements(vkcontext.logicalDevice, vkcontext.depthImage, &memoryRequirements);

	VkMemoryAllocateInfo imageAllocationInfo;
	imageAllocationInfo.allocationSize = memoryRequirements.size;

	uint memoryTypeBits = memoryRequirements.memoryTypeBits;
	VkMemoryPropertyFlags desiredMemoryFlags = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT;

	foreach(index; iota(0, 32)){
		VkMemoryType memoryType = vkcontext.memoryProperties.memoryTypes[index];
		if(memoryTypeBits & 1){
			if((memoryType.propertyFlags & desiredMemoryFlags) is desiredMemoryFlags){
				imageAllocationInfo.memoryTypeIndex = index;
				writeln("found index at ", index);
				break;
			}
		}
		memoryTypeBits = memoryTypeBits >> 1;
	}

	VkDeviceMemory imageMemory;
	enforceVk(vkAllocateMemory(vkcontext.logicalDevice, &imageAllocationInfo, null, &imageMemory));

	enforceVk(vkBindImageMemory(vkcontext.logicalDevice, vkcontext.depthImage, imageMemory, 0));

	//Render

	bool shouldClose = false;
	while(!shouldClose){
		SDL_Event event;
		while(SDL_PollEvent(&event)){
			if(event.type is SDL_QUIT){
				shouldClose = true;
			}
		}

//	  uint nextImageIdx = 0;
//    enforceVk(vkAcquireNextImageKHR(
//			vkcontext.logicalDevice,
//			vkcontext.swapchain,
//			ulong.max,
//			null, submitFence, &nextImageIdx
//		));
//
//    VkPresentInfoKHR presentInfo;
//    presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
//    presentInfo.pNext = null;
//    presentInfo.waitSemaphoreCount = 0;
//    presentInfo.pWaitSemaphores = null;
//    presentInfo.swapchainCount = 1;
//    presentInfo.pSwapchains = &vkcontext.swapchain;
//    presentInfo.pImageIndices = &nextImageIdx;
//    presentInfo.pResults = null;
//    vkQueuePresentKHR( vkcontext.presentQueue, &presentInfo );
	}





}
