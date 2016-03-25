import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import std.regex;

extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mode) nothrow
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}
static immutable string vertex = q{
  #version 330 core
  layout (location = 0) in vec3 pos;
  layout (location = 1) in vec3 col;
  out vec3 vs_col;
  void main(){
    gl_Position = vec4(pos.x, pos.y, pos.z, 1);
    vs_col = col;
  }
};
static immutable string fragment = q{
  #version 330 core
  in vec3 vs_col;
  out vec4 color;
  void main(){
    color = vec4(vs_col, 1);
  }
};


void main()
{

    import std.meta;
    import breeze.graphics.opengl.shader;
    import breeze.graphics.opengl.types;
    import breeze.graphics.opengl.buffer;
    import breeze.math.vector;
    import std.conv;
    import std.range;
    import derelict.enet.enet;

    DerelictENet.load();
    writeln("enet ",enet_initialize());
    DerelictGLFW3.load();
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

    struct Vertex{
        Vec3f position;
        Vec3f color;
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

    string vertexBody = q{
        void main(){
          gl_Position = vec4(position.x, position.y, position.z, 1);
          out_color = color;
        }
    }.outdent;

    auto vs = VertexShader!(VertexInput, VertexOutput)(vertexBody);

    static immutable string fragmentBody = q{
        void main(){
          frag_color = vec4(out_color, 1);
        }
    }.outdent;

    auto fs = FragmentShader!(FragmentInput, FragmentOutput)(fragmentBody);

    auto shader = createTypeSafeShader(vs, fs);

    Vertex[4] v2 = [
    Vertex(Vec3f(0.5f, 0.5, 0.0f), Vec3f(1.0f, 0.0f, 0.0f)),
        Vertex(Vec3f(0.5f, -0.5, 0.0f),Vec3f(0.0f, 1.0f, 0.0f)),
        Vertex(Vec3f(-0.5f, -0.5, 0.0f),Vec3f(0.0f, 0.0f, 1.0f)),
        Vertex(Vec3f(-0.5f, 0.5, 0.0f),Vec3f(1.0f, 0.0f, 1.0f))
    ];
    GLuint[6] indices = [  // Note that we start from 0!
    0, 1, 3,  // First Triangle
        1, 2, 3   // Second Triangle
        ];
    import std.container: Array;
    Array!int indices2 = [  // Note that we start from 0!
    0, 1, 3,  // First Triangle
        1, 2, 3   // Second Triangle
        ];

    auto vertexBuffer = createVertexBuffer(v2);

    import std.conv;
    auto ebo = createElementBuffer(indices[]);
    while (!glfwWindowShouldClose(window)){
        glfwPollEvents();
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        glUseProgram(shader.program.handle);
        draw(vertexBuffer, ebo, DrawMode.Triangles);

        glfwSwapBuffers(window);
    }
}
