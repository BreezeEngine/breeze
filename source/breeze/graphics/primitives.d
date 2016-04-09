module breeze.graphics.primitives;


struct Cube{
    import breeze.math.vector;
    import derelict.opengl3.types;
    struct VertexInput{
        Vec3f position;
        Vec2f uv;
    }
    static VertexInput[8] data = [
        VertexInput(Vec3f(-0.5f, -0.5f, 0.5f), Vec2f(0, 0)),
        VertexInput(Vec3f( 0.5f, -0.5f, 0.5f), Vec2f(1, 0)),
        VertexInput(Vec3f( 0.5f,  0.5f, 0.5f), Vec2f(1, 1)),
        VertexInput(Vec3f(-0.5f,  0.5f, 0.5f), Vec2f(0, 1)),

        VertexInput(Vec3f(-0.5f, -0.5f, -0.5f), Vec2f(0, 0)),
        VertexInput(Vec3f( 0.5f, -0.5f, -0.5f), Vec2f(1, 0)),
        VertexInput(Vec3f( 0.5f,  0.5f, -0.5f), Vec2f(1, 1)),
        VertexInput(Vec3f(-0.5f,  0.5f, -0.5f), Vec2f(0, 1)),
    ];

    static GLuint[6 * 6] indices = [
        //front
        0, 1, 2, 2, 3, 0,
        ////back
        5, 4, 7, 7, 6, 5,
        //right
        1, 5, 6, 6, 2, 1,
        //left
        4, 0, 3, 3, 7, 4,
        //top
        3, 2, 6, 6, 7, 3,
        //bot
        0, 1, 5, 5, 4, 0
    ];
}
