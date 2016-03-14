import std.stdio;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;

extern(C) void key_callback(GLFWwindow* window, int key, int scancode, int action, int mode) nothrow
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}
static const char* vertex = q{
  #version 330 core
  layout (location = 0) in vec3 pos;
  void main(){
    gl_Position = vec4(pos.x, pos.y, pos.z, 1);
  }
};
static const char* fragment = q{
  #version 330 core
  out vec4 color;
  void main(){
    color = vec4(1, 0, 0, 1);
  }
};


void main()
{

    import std.meta;
    import breeze.graphics.opengl.shader;
    import breeze.graphics.opengl.types;
    import breeze.graphics.opengl.buffer;
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

    auto vs = createShader!(ShaderType.Vertex)(vertex);
    auto fs = createShader!(ShaderType.Fragment)(fragment);
    auto program = createShaderProgram(vs, fs);

    GLfloat[12] vertices = [
    0.5f,  0.5f, 0.0f,  // Top Right
        0.5f, -0.5f, 0.0f,  // Bottom Right
         -0.5f, -0.5f, 0.0f,  // Bottom Left
         -0.5f,  0.5f, 0.0f   // Top Left 
    ];
    GLuint[6] indices = [  // Note that we start from 0!
    0, 1, 3,  // First Triangle
        1, 2, 3   // Second Triangle
        ];

    GLuint VAO;
    glGenVertexArrays(1, &VAO);
    // Bind the Vertex Array Object first, then bind and set vertex buffer(s) and attribute pointer(s).
    glBindVertexArray(VAO);

    auto vbo = createBuffer!(BufferType.Array);
    bufferData(vbo, vertices);

    auto ebo = createBuffer!(BufferType.Element);
    bufferData(ebo, indices);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * GLfloat.sizeof, null);
    glEnableVertexAttribArray(0);

    glBindBuffer(GL_ARRAY_BUFFER, 0); // Note that this is allowed, the call to glVertexAttribPointer registered VBO as the currently bound vertex buffer object so afterwards we can safely unbind

    glBindVertexArray(0); // Unbind VAO (it's always a good thing to unbind any buffer/array to prevent strange bugs), remember: do NOT unbind the EBO, keep it bound to this VAO

    while (!glfwWindowShouldClose(window)){
        glfwPollEvents();
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Draw our first triangle
        glUseProgram(program.handle);
        glBindVertexArray(VAO);
        //glDrawArrays(GL_TRIANGLES, 0, 6);
        glDrawElements(GL_TRIANGLES, 3, GL_UNSIGNED_INT, null);
        glBindVertexArray(0);

        glfwSwapBuffers(window);
    }
}
