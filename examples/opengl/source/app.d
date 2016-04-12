import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.regex;

struct Window{
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
struct FPCamera{
  import breeze.math.matrix;
  import breeze.math.vector;
  Window* window;
  Vec3f position;
  Vec3f direction;

  this(Window* w, Vec3f _position, Vec3f _direction){
    window = w;
    position = _position;
    direction = _direction;
  }
  Mat4f calcView(){
        auto mouseDelta = window.getDeltaMousePos / window.height;
        auto newDir = rotY((mouseDelta.x)) * Vec4f(direction, 1) ;
        direction = newDir.xyz;
        auto view = lookAt(position, position + direction, Vec3f(0, 1, 0));
        return view;
  }
}
struct AxisState{
    int key;
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
            if(window.getKey(axisState.key)){
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
            actionBindings[index].insert(key);
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

    Window w = Window(800, 600, "Test");
    auto input = InputMap!(Axis!("Forward", "Right"), Action!("Exit"))(&w);
    input.action!"Exit"(GLFW_KEY_ESCAPE);
    input.axis!"Forward"(
        AxisState(GLFW_KEY_W, 1.0f),
        AxisState(GLFW_KEY_S, -1.0f)
    );
    input.axis!"Right"(
        AxisState(GLFW_KEY_D, 1.0f),
        AxisState(GLFW_KEY_A, -1.0f)
    );

    struct Vertex{
        Vec3f position;
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

    auto vs = VertexShader!(Cube.VertexInput, VertexOutput, Uniforms)(vertexBody);

    static immutable string fragmentBody = q{
        void main(){
            frag_color = vec4(out_color, 1);
        }
    }.outdent;

    auto fs = FragmentShader!(FragmentInput, FragmentOutput, Uniforms)(fragmentBody);

    auto shader = createTypeSafeShader(vs, fs);

    auto vertexBuffer = createVertexBuffer(Cube.data);
    auto ebo = createElementBuffer(Cube.indices[]);

    //auto view = Mat4f.identity;
    auto proj = projection(PI/2, 4.0f/3.0f, 0.1f, 100);
    float frame = 0.0f;
    glfwSetInputMode(w.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    auto cam = FPCamera(&w, Vec3f(0, 0, 2), Vec3f(0, 0, -1));
    w.mainLoop((ref w){
        if (input.getAction!"Exit"){
            glfwSetWindowShouldClose(w.window, true);
        }
        float fwd = input.getAxis!"Forward";
        float right = input.getAxis!"Right";
        writeln(w.getDeltaMousePos);
        auto view = cam.calcView();
        //auto view = lookAt(Vec3f(0, 0, 2), Vec3f(0, 0, 0), Vec3f(0, 1, 0));
        draw(shader, vertexBuffer, ebo, DrawMode.Triangles, Uniforms(proj, view, rotY(frame)));
        frame += 0.01f;
    });
}
