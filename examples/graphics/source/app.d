import breeze.graphics.context;
import std.stdio;
import erupted;


void enforceVk(VkResult res){
  import std.exception;
  import std.conv;
  enforce(res is VkResult.VK_SUCCESS, res.to!string);
}

import breeze.util.array;
import containers.dynamicarray;
void main()
{
    import std.traits;
    import std.algorithm.iteration;
    import option;
    import std.typecons;
    import derelict.sdl2.sdl;
    import std.exception;
    DerelictSDL2.load();

    string[2] ext = [
        "VK_KHR_surface",
        "VK_KHR_xlib_surface"
     ];
    string[1] deviceExtensions = ["VK_KHR_swapchain"];
    string[1] validtionLayers = ["VK_LAYER_LUNARG_standard_validation"];
    auto validtionLayers2 = Array!string();
    auto validtionLayers3 = DynamicArray!string();
    auto instance = createInstance(
        "breeze",
        VK_MAKE_VERSION(1, 0, 13),
        ext,
        validtionLayers
    );
    auto sdlWindow = SDL_CreateWindow("vulkan", 0, 0, 800, 600, 0);
    auto pd = instance.physicalDevices;
    auto surface = instance.createSurfaceFromSdl(sdlWindow);
    auto capableDevices = pd[].findCapableDevices(surface);
    enforce(!capableDevices.empty, "Could not find any capable device");
    auto deviceIndex = capableDevices.front;
    writeln(capableDevices);
    auto device = createDevice(deviceIndex, deviceExtensions[], validtionLayers[]);
}
