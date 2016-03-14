module glad.gl.types;


alias GLfixed = int;
alias GLubyte = ubyte;
alias GLclampx = int;
alias GLenum = uint;
alias GLsizeiptr = ptrdiff_t;
alias GLdouble = double;
alias GLhalfARB = ushort;
alias GLshort = short;
alias GLclampd = double;
alias GLsizeiptrARB = ptrdiff_t;
alias GLuint = uint;
alias GLsizei = int;
alias GLint = int;
alias GLushort = ushort;
alias GLclampf = float;
alias GLintptrARB = ptrdiff_t;
alias GLcharARB = byte;
alias GLuint64EXT = ulong;
alias GLfloat = float;
alias GLboolean = ubyte;
alias GLuint64 = ulong;
alias GLint64EXT = long;
alias GLint64 = long;
alias GLchar = char;
alias GLeglImageOES = void*;
alias GLhalfNV = ushort;
alias GLintptr = ptrdiff_t;
alias GLhandleARB = uint;
alias GLhalf = ushort;
alias GLbitfield = uint;
alias GLvdpauSurfaceNV = ptrdiff_t;
alias GLvoid = void;
alias GLbyte = byte;
struct ___GLsync; alias __GLsync = ___GLsync*;
alias GLsync = __GLsync*;
struct __cl_context; alias _cl_context = __cl_context*;
struct __cl_event; alias _cl_event = __cl_event*;
extern(System) {
alias GLDEBUGPROC = void function(GLenum, GLenum, GLuint, GLenum, GLsizei, in GLchar*, GLvoid*);
alias GLDEBUGPROCARB = GLDEBUGPROC;
alias GLDEBUGPROCKHR = GLDEBUGPROC;
alias GLDEBUGPROCAMD = void function(GLuint, GLenum, GLenum, GLsizei, in GLchar*, GLvoid*);
}
