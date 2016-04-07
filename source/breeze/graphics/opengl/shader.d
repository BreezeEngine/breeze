module breeze.graphics.opengl.shader;


import std.stdio;
import derelict.opengl3.gl3;
import breeze.graphics.opengl.types;
import std.meta: allSatisfy;
import breeze.math.vector;
import breeze.math.matrix;

struct Shader(ShaderType _shaderType){
    GLuint handle;
    static immutable shaderType = _shaderType;
}

auto createShader(ShaderType shaderType)(string shaderSource){
    GLuint handle = glCreateShader(shaderType);
    const char* s = shaderSource.ptr;
    glShaderSource(handle, 1, &s, null);
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

struct TypeSafeShader(_Vertex, _Fragment){
    ShaderProgram program;
    alias Vertex = _Vertex;
    alias Fragment = _Fragment;
    alias Uniform = Vertex.Uniform;
    void send(string name, T)(const auto ref T value){
        alias Uniform = Vertex.Uniform;
        alias VerteXInput = Vertex.Input;
        auto loc = glGetUniformLocation(program.handle, name);
        send(loc, value);
    }
    void send(GLuint loc, Vec3f v){
        glUniform3f(loc, v.x, v.y, v.z);
    }
    void send(GLuint loc, Vec2f v){
        glUniform2f(loc, v.x, v.y);
    }
    void send(GLuint loc, float f){
        glUniform1f(loc, f);
    }
    void send(GLuint loc, Mat4f m){
        glUniformMatrix4fv(loc, 1, true, cast(GLfloat*)m.data);
    }
}

auto createTypeSafeShader(Vertex, Fragment)(Vertex vertex, Fragment fragment){
    auto program = createShaderProgram(vertex.shader, fragment.shader);
    return TypeSafeShader!(Vertex, Fragment)(program);
}

struct TypeToString(T, string s){
    alias Type = T;
    static immutable stringType = s;
}
enum isTypeToString(T) = std.traits.isInstanceOf!(TypeToString,T);
template StringTypeGen(T, ShaderTypes...)
  if(allSatisfy!(isTypeToString, ShaderTypes)
     && ShaderTypes.length > 0)
{
  static if(is(ShaderTypes[0].Type == T) ){
    alias StringTypeGen = ShaderTypes[0].stringType;
  }
  else static if(ShaderTypes.length == 1){
    static assert(false,stringType ~ " is not a recognized type.");
  }
  else{
    alias StringTypeGen = StringTypeGen!(T, ShaderTypes[1..$]);
  }
}

enum toGLSLString(T) = StringTypeGen!(T,
            TypeToString!(float, "float"),
            TypeToString!(Vector!(float, 2), "vec2"),
            TypeToString!(Vector!(float, 3), "vec3"),
            TypeToString!(Vector!(float, 4), "vec4"),
            TypeToString!(Matrix!(float, 3, 3), "mat3"),
            TypeToString!(Matrix!(float, 4, 4), "mat4"),
            TypeToString!(float, "float"),
            TypeToString!(GLfloat, "float"),
            TypeToString!(int, "int"),
            TypeToString!(GLint, "int"),
    );
auto glslMetaInput(T, bool withLoc)(){
    import std.meta: AliasSeq;
    import std.conv: to;
    alias Members = AliasSeq!(__traits(allMembers, T));
    alias toType(string s) = typeof(__traits(getMember, T, s));
    string[Members.length] input;
    foreach(index, name; Members){
        alias glslType = toType!name;
        static if(withLoc){
            string inputString = "layout (location = " ~ to!string(index) ~") in ";
        }
        else{
            string inputString = "in ";
        }
        input[index] =  inputString ~ toGLSLString!(toType!name) ~ " " ~ name ~";";
    }
    return input;
}
auto glslMetaOutput(T)(){
    import std.meta: AliasSeq;
    import std.conv: to;
    alias Members = AliasSeq!(__traits(allMembers, T));
    alias toType(string s) = typeof(__traits(getMember, T, s));
    string[Members.length] input;
    foreach(index, name; Members){
        alias glslType = toType!name;
        input[index] = "out " ~ toGLSLString!(toType!name) ~ " " ~ name ~";";
    }
    return input;
}
auto glslMetaUniform(T)(){
    import std.meta: AliasSeq;
    import std.conv: to;
    alias Members = AliasSeq!(__traits(allMembers, T));
    alias toType(string s) = typeof(__traits(getMember, T, s));
    string[Members.length] input;
    foreach(index, name; Members){
        alias glslType = toType!name;
        input[index] = "uniform " ~ toGLSLString!(toType!name) ~ " " ~ name ~";";
    }
    return input;
}

struct VertexShader(_Input, Output, _Uniform){
    alias Input = _Input;
    alias Uniform = _Uniform;
    Shader!(ShaderType.Vertex) shader;
    this(string shaderBody){
        import std.range: join;
        import std.algorithm: map;
        string input = glslMetaInput!(Input, true)[].map!(s => s ~ "\n").join();
        string output = glslMetaOutput!(Output)[].map!(s => s ~ "\n").join();
        string uniform = glslMetaUniform!(Uniform)[].map!(s => s ~ "\n").join();
        shader = createShader!(ShaderType.Vertex)("#version 330 core\n" ~ uniform ~ input ~ output ~ shaderBody);
    }
}
struct FragmentShader(Input, Output, Uniform){
    Shader!(ShaderType.Fragment) shader;
    this(string shaderBody){
        import std.range: join;
        import std.algorithm: map;
        string input = glslMetaInput!(Input, false)[].map!(s => s ~ "\n").join();
        string output = glslMetaOutput!(Output)[].map!(s => s ~ "\n").join();
        string uniform = glslMetaUniform!(Uniform)[].map!(s => s ~ "\n").join();
        shader = createShader!(ShaderType.Fragment)("#version 330 core\n"~ uniform  ~ input ~ output ~ shaderBody);
    }
}
struct Shader(Input, Output){
    string shaderBody;
    string compile(){
        import std.range: join;
        import std.algorithm: map;
        string input = glslMetaInput!(Input)[].map!(s => s ~ "\n").join();
        string output = glslMetaOutput!(Output)[].map!(s => s ~ "\n").join();
        return "#version 330 core\n" ~ input ~ output ~ shaderBody;
    }
}
