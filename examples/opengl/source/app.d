import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.regex;

extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mode) nothrow
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}

void main()
{
    import std.meta;
    import breeze.graphics.opengl.shader;
    import breeze.graphics.opengl.types;
    import breeze.graphics.opengl.buffer;
    import breeze.math.vector;
    import std.conv;
    import std.range;
    import breeze.math.matrix;
    import std.math;

    DerelictGL3.load();
    glfwInit();
    // Set all the required options for GLFW
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, false);

    // Create a GLFWwindow object that we can use for GLFW's functions
    GLFWwindow* window = glfwCreateWindow(800, 600, "LearnOpenGL", null, null);
    glfwMakeContextCurrent(window);

    // Set the required callback functions
    glfwSetKeyCallback(window, &key_callback);

    // Set this to true so GLEW knows to use a modern approach to retrieving function pointers and extensions
    //glewExperimental = GL_TRUE;
    // Initialize GLEW to setup the OpenGL Function pointers
    //glewInit();
    DerelictGL3.reload;

    // Define the viewport dimensions
    glViewport(0, 0, 800, 600);
    glEnable(GL_DEPTH_TEST);

    struct Vertex{
        Vec3f position;
        Vec2f uv;
    }

    struct Uniforms{
        Vec3f ucolor;
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

    import breeze.graphics.opengl.shader;
    import std.string;
    import breeze.graphics.primitives: Cube;

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

    Vertex[4] v2 = [
        Vertex(Vec3f(0.5f, 0.5, 0.0f),  Vec2f(1.0f, 0.0f)),
        Vertex(Vec3f(0.5f, -0.5, 0.0f), Vec2f(0.0f, 1.0f)),
        Vertex(Vec3f(-0.5f, -0.5, 0.0f),Vec2f(0.0f, 0.0f)),
        Vertex(Vec3f(-0.5f, 0.5, 0.0f), Vec2f(1.0f, 0.0f))
    ];
    GLuint[6] indices = [
        0, 1, 3,  // First Triangle
        1, 2, 3   // Second Triangle
    ];
    import std.container: Array;
    Array!int indices2 = [  // Note that we start from 0!
        0, 1, 3,  // First Triangle
        1, 2, 3   // Second Triangle
    ];

    auto vertexBuffer = createVertexBuffer(v2);

    auto vertexBuffer2 = createVertexBuffer(Cube.data);
    auto ebo2 = createElementBuffer(Cube.indices[]);

    auto view = lookAt(Vec3f(0, 0, 10), Vec3f(0, 0, 0), Vec3f(0, 1, 0));
    writeln((view));
    //auto view = translate(Vec3f(0, 0, 2));
    auto proj = projection(PI/4, 4.0f/3.0f, 0.1f, 100);
    import std.range;
    import std.conv;
    auto ebo = createElementBuffer(indices[]);
    float frame = 0.0f;
    while (!glfwWindowShouldClose(window)){
        glfwPollEvents();
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        draw(shader, vertexBuffer2, ebo2, DrawMode.Triangles, Uniforms(Vec3f(1, 0, 0), proj, view, rotZ(frame)));
        //frame += 0.01;
        //draw(shader, vertexBuffer, ebo, DrawMode.Triangles, Uniforms(Vec3f(1, 0, 0), 1.0f));

        glfwSwapBuffers(window);
    }
}
