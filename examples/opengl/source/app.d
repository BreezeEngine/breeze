import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.regex;


struct FPCamera{
    import breeze.input;
  import breeze.math.matrix;
  import breeze.math.vector;
        import breeze.math.units;
  alias Input = InputMap!(Axis!("Forward", "Right"), Action!("Exit"));
  Input input;
  Window* window;
  Vec3f position;

  Vec3f forward = Vec3f(0, 0, -1);
  Vec3f up = Vec3f(0, 1, 0);

  Degrees xAngle;
  Degrees yAngle;

  this(Window* w, Vec3f _position, Vec3f _direction){
    window = w;
    position = _position;
    xAngle = Degrees(0);
    yAngle = Degrees(0);
    input = Input(w);
    input.axis!"Forward"(
        AxisState(Key.w, 1.0f),
        AxisState(Key.s, -1.0f)
    );
    input.axis!"Right"(
        AxisState(Key.d, 1.0f),
        AxisState(Key.a, -1.0f)
    );
  }
  Mat4f calcView(){
        auto mouseDelta = window.getDeltaMousePos * 50 / window.height;
        xAngle += Degrees(mouseDelta.x);
        yAngle += Degrees(mouseDelta.y);
        import std.algorithm.comparison: clamp;
        yAngle = Degrees(clamp(yAngle.value, -89.5, 89.5));
        auto newDir = rotY(Radians(xAngle).value) * rotX(Radians(yAngle).value) * Vec4f(forward, 1) ;
        auto direction = newDir.xyz;
        auto right = (rotY(Radians(xAngle).value) * Vec4f(1, 0, 0, 1)).xyz;
        auto fwd = input.getAxis!"Forward";
        auto rt = input.getAxis!"Right";
        position = position + direction * fwd * 0.05f;
        position = position + right * rt * 0.05f;

        //writeln(direction);
        auto view = lookAt(position, position + direction, up);
        return view;
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

    writeln(getKeyFromString("f3"));
    Window w = Window(1920, 1080, "Test");
    auto input = InputMap!(Axis!("Forward", "Right")
                          ,Action!("Exit"))(&w);
    input.action!"Exit"(Key.escape);

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
    glfwSetInputMode(w.window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    auto cam = FPCamera(&w, Vec3f(0, 0, 2), Vec3f(0, 0, -1));
    import breeze.util.obj;
    import containers.dynamicarray;
    DynamicArray!Mesh mesh = parsObj("/home/maik/projects/breeze/bin/akm.obj");
    auto vertexBuffer2 = createVertexBuffer!Mesh(mesh[]);
    w.mainLoop((ref w){
        if (input.getAction!"Exit"){
            glfwSetWindowShouldClose(w.window, true);
        }
        float fwd = input.getAxis!"Forward";
        float right = input.getAxis!"Right";
        //writeln(w.getDeltaMousePos);
        auto view = cam.calcView();
        //auto view = lookAt(Vec3f(0, 0, 2), Vec3f(0, 2, 0), Vec3f(0, 1, 0));
        draw(shader, vertexBuffer2, DrawMode.Triangles, Uniforms(proj, view, rotX(frame)));
        frame += 0.01f;
    });
}
