module breeze.graphics.opengl.buffer;
import derelict.opengl3.gl3;
import breeze.graphics.opengl.types;
struct Buffer(BufferType bufferType){
    GLuint handle;
    void bind(){
        glBindBuffer(bufferType, handle);
    }
    void unbind(){
        glBindBuffer(bufferType, 0);
    }
}

auto createBuffer(BufferType bufferType)(){
    GLuint handle;
    glGenBuffers(1, &handle);
    return Buffer!bufferType(handle);
}

void bufferData(T, BufferType bufferType)(Buffer!bufferType buffer, const auto ref T data){
    buffer.bind();
    glBufferData(bufferType, data.sizeof, &data, GL_STATIC_DRAW);
}


