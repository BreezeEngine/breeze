module breeze.graphics.opengl.types;

import derelict.opengl3.gl3;
enum ShaderType{
    Vertex = GL_VERTEX_SHADER,
    Fragment = GL_FRAGMENT_SHADER
}

enum BufferType{
    Array = GL_ARRAY_BUFFER,
    Element = GL_ELEMENT_ARRAY_BUFFER
}

enum PrimitiveType{
    Int = GL_INT,
    UInt = GL_UNSIGNED_INT,
    Float = GL_FLOAT,
}

enum DrawMode{
    Triangles = GL_TRIANGLES,
    Line = GL_LINE,
    Points = GL_POINTS,
}

