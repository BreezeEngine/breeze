module breeze.graphics.opengl.shader;


import std.stdio;
import derelict.opengl3.gl3;
import breeze.graphics.opengl.types;

struct Shader(ShaderType _shaderType){
    GLuint handle;
    static immutable shaderType = _shaderType;
}

auto createShader(ShaderType shaderType)(const char* shaderSource){
    GLuint handle = glCreateShader(shaderType);
    glShaderSource(handle, 1, &shaderSource, null);
    glCompileShader(handle);

    GLint success;
    glGetShaderiv(handle, GL_COMPILE_STATUS, &success);
    if (!success){
        GLchar[512] infoLog;
        GLsizei length;
        glGetShaderInfoLog(handle, 512, &length, infoLog.ptr);
        writeln(infoLog[0 .. length]);
        assert(false, infoLog[0 .. length]);
    }
    return Shader!(shaderType)(handle);
}

unittest{
    //auto s = createShader!(ShaderType.Vertex)("");
}

struct ShaderProgram{
    GLuint handle;
}
ShaderProgram createShaderProgram(Shader!(ShaderType.Vertex) vs, Shader!(ShaderType.Fragment) fs){
    GLuint shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vs.handle);
    glAttachShader(shaderProgram, fs.handle);
    glLinkProgram(shaderProgram);

    GLint success;
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        GLchar[512] infoLog;
        GLsizei length;
        glGetProgramInfoLog(shaderProgram, 512, &length, infoLog.ptr);
        assert(false, infoLog[0 .. length]);
    }
    return ShaderProgram(shaderProgram);
}

