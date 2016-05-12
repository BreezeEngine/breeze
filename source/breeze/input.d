module breeze.input;
import option;

enum Key{
    unknown,
    space,
    apostrophe,
    comma,
    minus,
    period,
    slash,
    num0,
    num1,
    num2,
    num3,
    num4,
    num5,
    num6,
    num7,
    num8,
    num9,
    semicolon,
    equal,
    a,
    b,
    c,
    d,
    e,
    f,
    g,
    h,
    i,
    j,
    k,
    l,
    m,
    n,
    o,
    p,
    q,
    r,
    s,
    t,
    u,
    v,
    w,
    x,
    y,
    z,
    leftBracket,
    backslash,
    rightBracket,
    graveAccent,
    world1,
    world2,
    escape,
    enter,
    tab,
    backspace,
    insert,
    del,
    right,
    left,
    down,
    up,
    pageUp,
    pageDown,
    home,
    end,
    capsLock,
    scrollLock,
    numLock,
    printScreen,
    pause,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    f25,
    kp0,
    kp1,
    kp2,
    kp3,
    kp4,
    kp5,
    kp6,
    kp7,
    kp8,
    kp9,
    kpDecimal,
    kpDivide,
    kpMultiply,
    kpSubtract,
    kpAdd,
    kpEnter,
    kpEqual,
    leftShift,
    leftControl,
    leftAlt,
    leftSuper,
    rightShift,
    rightControl,
    rightAlt,
    rightSuper,
    menu,
    last
}

enum numberOfKeys = __traits(allMembers, Key).length;
import containers.dynamicarray;
enum int[numberOfKeys] glfwLookupArray(){
    import std.stdio;
    int[numberOfKeys] glfw = 
        [-1,
        32,
        39,
        44,
        45,
        46,
        47,
        48,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56,
        57,
        59,
        61,
        65,
        66,
        67,
        68,
        69,
        70,
        71,
        72,
        73,
        74,
        75,
        76,
        77,
        78,
        79,
        80,
        81,
        82,
        83,
        84,
        85,
        86,
        87,
        88,
        89,
        90,
        91,
        92,
        93,
        96,
        161,
        162,
        256,
        257,
        258,
        259,
        260,
        261,
        262,
        263,
        264,
        265,
        266,
        267,
        268,
        269,
        280,
        281,
        282,
        283,
        284,
        290,
        291,
        292,
        293,
        294,
        295,
        296,
        297,
        298,
        299,
        300,
        301,
        302,
        303,
        304,
        305,
        306,
        307,
        308,
        309,
        310,
        311,
        312,
        313,
        314,
        320,
        321,
        322,
        323,
        324,
        325,
        326,
        327,
        328,
        329,
        330,
        331,
        332,
        333,
        334,
        335,
        336,
        340,
        341,
        342,
        343,
        344,
        345,
        346,
        347,
        348,
        348];
    return glfw;
}
Option!Key getKeyFromString(string keyName){
    import std.string: toLower;
    foreach(_keyName; __traits(allMembers, Key)){
        if(keyName.toLower is _keyName){
            return some(__traits(getMember, Key, _keyName));
        }
    }
    return none!Key;
}
struct Window{
    import derelict.glfw3.glfw3;
    import derelict.opengl3.gl3;
    import breeze.math.vector;
    GLFWwindow* window;
    Vec2d lastMousePos;
    int width, height;
    this(int _width, int _height, string title){
        height = _height;
        width = _width;
        DerelictGL3.load();
        glfwInit();
        // Set all the required options for GLFW
        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
        glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
        glfwWindowHint(GLFW_RESIZABLE, false);

        // Create a GLFWwindow object that we can use for GLFW's functions
        window = glfwCreateWindow(width, height, title.ptr, null, null);
        glfwMakeContextCurrent(window);
        DerelictGL3.reload;

        // Define the viewport dimensions
        glViewport(0, 0, width, height);
        glEnable(GL_DEPTH_TEST);
        glEnable(GL_CULL_FACE);

        glfwSetMouseButtonCallback(window, (w, bt, act, mod){
                import std.stdio;
                try{
                writeln("Mouse: ", bt, " ", act);
                }
                catch(Exception e){}
        });
        glfwSetScrollCallback(window, (w, x, y){
                import std.stdio;
                try{
                writeln("Mouse: ", x, " ", y);
                }
                catch(Exception e){}
        });
    }
    auto getMousePos(){
      double x = void;
      double y = void;
      glfwGetCursorPos(window, &x, &y);
      return Vec2d(x, y);
    }
    auto ref getLastMousePos(){
      return lastMousePos;
    }
    auto getDeltaMousePos(){
      return lastMousePos - getMousePos();
    }
    void mainLoop(void delegate(ref Window) f){
        while (!glfwWindowShouldClose(window)){
            glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

            f(this);
            lastMousePos = getMousePos();
            glfwPollEvents();
            glfwSwapBuffers(window);
        }
    }
    bool getKey(int key){
        return glfwGetKey(window, key) == GLFW_PRESS;
    }
}
struct AxisState{
    Key key;
    float value;
}
struct Axis(_names...){
    alias names = _names;
}
struct Action(_names...){
    alias names = _names;
}
struct InputMap(Axis,Action){
    import option;
    import std.container: Array;

    Window* window;
    Array!AxisState[Axis.names.length] keys;
    Array!int[Action.names.length] actionBindings;
    void axis(string name, AxisState...)(AxisState axisStates){
        import std.meta: staticIndexOf;
        enum index = staticIndexOf!(name, Axis.names);
        foreach(axisState; axisStates){
            keys[index].insert(axisState);
        }
    }
    float getAxis(string name)(){
        import std.range;
        import std.meta: staticIndexOf;
        import std.algorithm.iteration: reduce;
        enum index = staticIndexOf!(name, Axis.names);
        float value = reduce!((acc, axisState){
            if(window.getKey(glfwLookupArray[axisState.key])){
                return acc + axisState.value;
            }
            return acc;
        })(0.0f, keys[index]);
        import std.algorithm.comparison: max, min;
        return value;
    }
    void action(string name, Keys...)(Keys keys){
        import std.meta: staticIndexOf;
        enum index = staticIndexOf!(name, Action.names);
        foreach(key; keys){
            import std.stdio;
            writeln(key);
            actionBindings[index].insert(glfwLookupArray[key]);
        }
    }
    bool getAction(string name)(){
        import std.range;
        import std.meta: staticIndexOf;
        import std.algorithm.iteration: reduce;
        enum index = staticIndexOf!(name, Action.names);
        foreach(key; actionBindings[index]){
            if(window.getKey(key)){
                return true;
            }
        }
        return false;
    }
    bool getKey(string name)(){
        //import std.meta: staticIndexOf;
        //enum index = staticIndexOf!(name, names);
        //return window.getKey(keys[index]);
        return true;
    }
}
