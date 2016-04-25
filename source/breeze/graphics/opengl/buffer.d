module breeze.graphics.opengl.buffer;
import derelict.opengl3.gl3;
import breeze.graphics.opengl.types;
import std.stdio;
import std.traits;

struct ElementBuffer(T){
    GLuint handle;
    size_t elements;
    void bind(){
        glBindBuffer(BufferType.Element, handle);
    }
    void unbind(){
        glBindBuffer(BufferType.Element, 0);
    }
}

import std.container: Array;
private auto createElementBufferImpl(T)(const auto ref T data){
    GLuint handle;
    glGenBuffers(1, &handle);
    glBindBuffer(BufferType.Element, handle);
    glBufferData(BufferType.Element, T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
    glBindBuffer(BufferType.Element, handle);
    return ElementBuffer!T(handle, data.length);
}
auto createElementBuffer(T)(const auto ref T[] data){
    return createElementBufferImpl(data);
}
auto createElementBuffer(T)(const auto ref Array!T data){
    return createElementBufferImpl(data);
}

//template structToTypes(T){
//    import std.meta;
//    alias Members = AliasSeq!(__traits(allMembers, T));
//    alias toType(string s) = typeof(__traits(getMember, T, s));
//    alias structToTypes = staticMap!(toType, Members);
//}


struct VertexBuffer(T){
    import containers.dynamicarray;
    GLuint vao;
    GLuint vbo;
    size_t elements;
    ~this(){
        glDeleteBuffers(1, &vbo);
        glDeleteVertexArrays(1, &vao);
    }
}

import breeze.math.vector;
uint numberOfelements(T, uint size)(Vector!(T, size)){
    return size;
}

uint numberOfelements(T, uint size)(T[size]){
    return size;
}
uint numberOfelements(T)(T)
if(isIntegral!T || isFloatingPoint!T){
    return 1;
}
//auto createVertexBuffer(T, Args...)(const auto ref Args args){
//    import std.range;
//    import std.algorithm.iteration;
//    ulong[Args.length] offsets;
//    foreach(index, ref container; args){
//        alias Type = ReturnType!(container.front);
//        offsets[index] = container.length * Type.sizeof;
//    }
//    import std.traits: ReturnType;
//    GLuint _vao;
//    glGenVertexArrays(1, &_vao);
//
//    glBindVertexArray(_vao);
//    GLuint _vbo;
//    glGenBuffers(1, &_vbo);
//
//    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
//    glBufferData(GL_ARRAY_BUFFER, offsets[].sum, null, GL_STATIC_DRAW);
//
//    foreach(index, ref container; args){
//        writeln(offsets[0 .. index]);
//        glBufferSubData(GL_ARRAY_BUFFER, offsets[0 .. index].sum, offsets[index], container.ptr);
//
//        alias Type = ReturnType!(container.front);
//        glEnableVertexAttribArray(index);
//        glVertexAttribPointer(cast(uint)index
//                             ,cast(int)container.length
//                             ,GL_FLOAT, GL_FALSE
//                             ,cast(int)offsets[index]
//                             ,cast(GLvoid*)(offsets[0 .. index].sum));
//    }
//    glBindBuffer(GL_ARRAY_BUFFER, 0);
//    glBindVertexArray(0);
//}
auto createVertexBuffer(T)(const auto ref T[] data){
    import std.meta;

    import std.traits: FieldNameTuple;
    alias Members = FieldNameTuple!T;
    //Broken report?
    //alias Members = AliasSeq!(__traits(allMembers, T));
    alias toType(string s) = typeof(__traits(getMember, T, s));
    enum toOffset(string s) = __traits(getMember, T, s).offsetof;

    alias Types = staticMap!(toType, Members);
    alias offsets = staticMap!(toOffset, Members);

    GLuint _vao;
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
    GLuint _vbo;
    glGenBuffers(1, &_vbo);

    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);

    foreach(index, type; Types){
        glEnableVertexAttribArray(index);
        enum elements = numberOfelements(type.init);
        writeln("size ", T.sizeof);
        glVertexAttribPointer(index, elements, GL_FLOAT, GL_FALSE, T.sizeof, cast(GLvoid*)(offsets[index]));
    }

    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);

    return VertexBuffer!T(_vao, _vbo, data.length);
}


void draw(T)(ref VertexBuffer!T buffer, DrawMode drawMode){
    glBindVertexArray(buffer.vao);
    glDrawArrays(drawMode, 0, cast(GLsizei)buffer.elements);
    glBindVertexArray(0);
}
void draw(T,E)(ref VertexBuffer!T buffer,ref ElementBuffer!E ebo, DrawMode drawMode){
    glBindVertexArray(buffer.vao);
    ebo.bind();
    glDrawElements(drawMode, cast(GLsizei)ebo.elements, GL_UNSIGNED_INT, null);
    glBindVertexArray(0);
    ebo.unbind();
}

void draw(Shader, Vbo, Uniform)(ref Shader shader, ref Vbo vbo,DrawMode drawMode, const auto ref Uniform uniform){
    import std.meta: AliasSeq;
    //static assert(is(Vbo == VertexBuffer!(Shader.Vertex.Input)));
    alias Members = AliasSeq!(__traits(allMembers, Uniform));
    glUseProgram(shader.program.handle);
    foreach(name; Members){
       shader.send!name(__traits(getMember, uniform, name));
    }
    draw(vbo, drawMode);
}
void draw(Shader, Vbo, Ebo, Uniform)(ref Shader shader, ref Vbo vbo, ref Ebo ebo, DrawMode drawMode, const auto ref Uniform uniform){
    import std.meta: AliasSeq;
    //static assert(is(Vbo == VertexBuffer!(Shader.Vertex.Input)));
    alias Members = AliasSeq!(__traits(allMembers, Uniform));
    glUseProgram(shader.program.handle);
    foreach(name; Members){
       shader.send!name(__traits(getMember, uniform, name));
    }
    draw(vbo, ebo, drawMode);
}



