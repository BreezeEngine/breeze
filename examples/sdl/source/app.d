import std.stdio;
import derelict.sdl2.sdl;

enum Key{
    unknown,
    backspace,
    tab,
    ret,
    escape,
    space,
    exclaim,
    quotedbl,
    hash,
    dollar,
    percent,
    ampersand,
    quote,
    leftparen,
    rightparen,
    asterisk,
    plus,
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
    colon,
    semicolon,
    less,
    equals,
    greater,
    question,
    at,
    leftbracket,
    backslash,
    rightbracket,
    caret,
    underscore,
    backquote,
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
    del,
    capslock,
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
    printscreen,
    scrolllock,
    pause,
    insert,
    home,
    pageup,
    end,
    pagedown,
    right,
    left,
    down,
    up,
    numlockclear,
    kpDivide,
    kpMultiply,
    kpMinus,
    kpPlus,
    kpEnter,
    kp1,
    kp2,
    kp3,
    kp4,
    kp5,
    kp6,
    kp7,
    kp8,
    kp9,
    kp0,
    kpPeriod,
    application,
    power,
    kpEquals,
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
    execute,
    help,
    menu,
    select,
    stop,
    again,
    undo,
    cut,
    copy,
    paste,
    find,
    mute,
    volumeup,
    volumedown,
    kpComma,
    kpEqualsas400,
    alterase,
    sysreq,
    cancel,
    clear,
    prior,
    return2,
    separator,
    keyOut,
    oper,
    clearagain,
    crsel,
    exsel,
    kp00,
    kp000,
    thousandsseparator,
    decimalseparator,
    currencyunit,
    currencysubunit,
    kpLeftparen,
    kpRightparen,
    kpLeftbrace,
    kpRightbrace,
    kpTab,
    kpBackspace,
    kpA,
    kpB,
    kpC,
    kpD,
    kpE,
    kpF,
    kpXor,
    kpPower,
    kpPercent,
    kpLess,
    kpGreater,
    kpAmpersand,
    kpDblampersand,
    kpVerticalbar,
    kpDblverticalbar,
    kpColon,
    kpHash,
    kpSpace,
    kpAt,
    kpExclam,
    kpMemstore,
    kpMemrecall,
    kpMemclear,
    kpMemadd,
    kpMemsubtract,
    kpMemmultiply,
    kpMemdivide,
    kpPlusminus,
    kpClear,
    kpClearentry,
    kpBinary,
    kpOctal,
    kpDecimal,
    kpHexadecimal,
    lctrl,
    lshift,
    lalt,
    lgui,
    rctrl,
    rshift,
    ralt,
    rgui,
    mode,
    audionext,
    audioprev,
    audiostop,
    audioplay,
    audiomute,
    mediaselect,
    www,
    mail,
    calculator,
    computer,
    acSearch,
    acHome,
    acBack,
    acForward,
    acStop,
    acRefresh,
    acBookmarks,
    brightnessdown,
    brightnessup,
    displayswitch,
    kbdillumtoggle,
    kbdillumdown,
    kbdillumup,
    eject,
    sleep
}

enum int[236] keycodes = [
    0,
    8,
    9,
    13,
    27,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
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
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    91,
    92,
    93,
    94,
    95,
    96,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
    113,
    114,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    127,
    1073741881,
    1073741882,
    1073741883,
    1073741884,
    1073741885,
    1073741886,
    1073741887,
    1073741888,
    1073741889,
    1073741890,
    1073741891,
    1073741892,
    1073741893,
    1073741894,
    1073741895,
    1073741896,
    1073741897,
    1073741898,
    1073741899,
    1073741901,
    1073741902,
    1073741903,
    1073741904,
    1073741905,
    1073741906,
    1073741907,
    1073741908,
    1073741909,
    1073741910,
    1073741911,
    1073741912,
    1073741913,
    1073741914,
    1073741915,
    1073741916,
    1073741917,
    1073741918,
    1073741919,
    1073741920,
    1073741921,
    1073741922,
    1073741923,
    1073741925,
    1073741926,
    1073741927,
    1073741928,
    1073741929,
    1073741930,
    1073741931,
    1073741932,
    1073741933,
    1073741934,
    1073741935,
    1073741936,
    1073741937,
    1073741938,
    1073741939,
    1073741940,
    1073741941,
    1073741942,
    1073741943,
    1073741944,
    1073741945,
    1073741946,
    1073741947,
    1073741948,
    1073741949,
    1073741950,
    1073741951,
    1073741952,
    1073741953,
    1073741957,
    1073741958,
    1073741977,
    1073741978,
    1073741979,
    1073741980,
    1073741981,
    1073741982,
    1073741983,
    1073741984,
    1073741985,
    1073741986,
    1073741987,
    1073741988,
    1073742000,
    1073742001,
    1073742002,
    1073742003,
    1073742004,
    1073742005,
    1073742006,
    1073742007,
    1073742008,
    1073742009,
    1073742010,
    1073742011,
    1073742012,
    1073742013,
    1073742014,
    1073742015,
    1073742016,
    1073742017,
    1073742018,
    1073742019,
    1073742020,
    1073742021,
    1073742022,
    1073742023,
    1073742024,
    1073742025,
    1073742026,
    1073742027,
    1073742028,
    1073742029,
    1073742030,
    1073742031,
    1073742032,
    1073742033,
    1073742034,
    1073742035,
    1073742036,
    1073742037,
    1073742038,
    1073742039,
    1073742040,
    1073742041,
    1073742042,
    1073742043,
    1073742044,
    1073742045,
    1073742048,
    1073742049,
    1073742050,
    1073742051,
    1073742052,
    1073742053,
    1073742054,
    1073742055,
    1073742081,
    1073742082,
    1073742083,
    1073742084,
    1073742085,
    1073742086,
    1073742087,
    1073742088,
    1073742089,
    1073742090,
    1073742091,
    1073742092,
    1073742093,
    1073742094,
    1073742095,
    1073742096,
    1073742097,
    1073742098,
    1073742099,
    1073742100,
    1073742101,
    1073742102,
    1073742103,
    1073742104,
    1073742105,
    1073742106
];
int[int] genKeycodeHash(){
    import std.range: iota;
    int[int] keyHash;
    foreach(index; iota(0, 236)){
        keyHash[keycodes[index]] = index;
    }
    return keyHash;
}
enum keycodeHash = genKeycodeHash();
enum KeyState{
    nothing,
    pressed,
    released,
}

//struct KeyState{
//    uint timestamp;
//    uint windowID;
//    bool repeat;
//}

KeyState addKeystate(KeyState currentState, KeyState nextState){
    if(currentState is KeyState.released && nextState is KeyState.pressed){
        return KeyState.released;
    }
    return nextState;
}



struct GLContext{
    SDL_GLContext context;
}
struct Window{
    import breeze.math.vector;
    import derelict.sdl2.sdl;
    import derelict.opengl3.gl3;
    SDL_Window* handle;
    Input* input;
    this(string title, int width, int height, Input* _input){
        DerelictSDL2.load();
        handle = SDL_CreateWindow(title.ptr, 0, 0, width, height, SDL_WINDOW_OPENGL);
        input = _input;
    }

    GLContext createGLContext(){
        DerelictGL3.load();
        auto sdlc = SDL_GL_CreateContext(handle);
        DerelictGL3.reload();
        return GLContext(sdlc);
    }

    ~this(){
        SDL_DestroyWindow(handle);
    }

    void setWindowPosition(Vec2i pos){
        SDL_SetWindowPosition(handle, pos.x, pos.y);
    }

    Vec2i getWindowPosition(){
        int x, y;
        SDL_GetWindowPosition(handle, &x, &y);
        return Vec2i(x, y);
    }

    void moveWindow(Vec2i dir){
        auto pos = getWindowPosition();
        setWindowPosition(pos + dir);
    }

    void mainLoop(void delegate(Input* input) f){
        bool shouldExit = false;
        while(!shouldExit){
            input.poll();
            foreach(ref ws; input.windowStates){
                if(SDL_GetWindowID(handle) is ws.handle){
                    shouldExit = true;
                }
            }
            glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            f(input);
            SDL_GL_SwapWindow(handle);
        }
    }
}

enum MouseKey{
    left,
    middle,
    right,
    x1,
    x2
}
struct Input{
    uint currentWindow;
    KeyState[236] keys;
    KeyState[5] mouseKeys;
    import containers.dynamicarray;
    struct WindowState{
        uint handle;
        bool shouldClose;
    }
    DynamicArray!WindowState windowStates;
    void poll(){
        foreach(ref key; keys){
            key = KeyState.nothing;
        }
        SDL_Event event;
        while(SDL_PollEvent(&event)){
            if(event.type is SDL_QUIT){
                windowStates.insert(WindowState(currentWindow, true));
            }
            if(event.type is SDL_WINDOWEVENT){
                if(event.window.event is SDL_WINDOWEVENT_FOCUS_GAINED){
                    currentWindow = event.window.windowID;
                }
            }
            if(event.type is SDL_KEYDOWN){
                keys[keycodeHash[event.key.keysym.sym]] = KeyState.pressed;
                writeln("-----------");
                writeln(event.key.timestamp);
                writeln(event.key.windowID);
                writeln(event.key.repeat);
            }
            if(event.type is SDL_KEYUP){
                keys[keycodeHash[event.key.keysym.sym]] = KeyState.released;
            }
            if(event.type is SDL_MOUSEBUTTONDOWN){
                mouseKeys[event.button.button - 1] = KeyState.pressed;
            }
            if(event.type is SDL_MOUSEBUTTONUP){
                mouseKeys[event.button.button - 1] = KeyState.released;
            }
            if(event.type is SDL_MOUSEWHEEL){
            }
            if(event.type is SDL_MOUSEMOTION){
            }
        }
    }
}

void main()
{
    import std.meta;
    import breeze.graphics.opengl.shader;
    import breeze.graphics.opengl.types;
    import breeze.graphics.opengl.buffer;
    import breeze.graphics.primitives: Cube;
    import std.conv;
    import std.range;
    import breeze.math.vector;
    import breeze.math.matrix;
    import std.math;
    import std.string;
    import breeze.input;
    import derelict.opengl3.gl3;
    auto input = Input();
    auto w = Window("Test", 720, 480, &input);
    auto context = w.createGLContext;
    struct Vertex{
        Vec3f position;
        Vec3f normal;
        Vec2f uv;
    }

    struct Uniforms{
        Mat4f uproj;
        Mat4f uview;
        Mat4f umodel;
    }

    alias VertexInput = Vertex;

    struct VertexOutput{
        Vec3f out_color;
    }

    alias FragmentInput = VertexOutput;

    struct FragmentOutput{
        Vec4f frag_color;
    }


    string vertexBody = q{
        void main(){
            gl_Position = uproj * uview * umodel * vec4(position, 1);
            out_color = vec3(uv, 0);
        }
    }.outdent;

    auto vs = VertexShader!(VertexInput, VertexOutput, Uniforms)(vertexBody);

    static immutable string fragmentBody = q{
        void main(){
            frag_color = vec4(out_color, 1);
        }
    }.outdent;

    auto fs = FragmentShader!(FragmentInput, FragmentOutput, Uniforms)(fragmentBody);

    auto shader = createTypeSafeShader(vs, fs);

    auto vertexBuffer = createVertexBuffer(Cube.data[]);
    auto ebo = createElementBuffer(Cube.indices[]);

    //auto view = Mat4f.identity;
    import breeze.math.units;
    auto proj = projection(Radians(Degrees(102)).value, 4.0f/3.0f, 0.1f, 100);
    float frame = 0.0f;
    import breeze.util.obj;
    import containers.dynamicarray;
    DynamicArray!Mesh mesh = parsObj("/home/maik/projects/breeze/bin/akm.obj");
    auto vertexBuffer2 = createVertexBuffer!Mesh(mesh[]);
    w.mainLoop((input){
        if(input.mouseKeys[MouseKey.left] is KeyState.pressed){
            //writeln("left");
        }
        auto view = lookAt(Vec3f(40, 0, 0), Vec3f(0, 2, 0), Vec3f(0, 1, 0));
        draw(shader, vertexBuffer2, DrawMode.Triangles, Uniforms(proj, view, rotX(frame)));
        frame += 0.01f;
        SDL_Delay(5000);
    });
}
