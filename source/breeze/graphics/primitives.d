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

        VertexInput(Vec3f(-0.5f, -0.5f, -0.5f), Vec2f(1, 1)),
        VertexInput(Vec3f( 0.5f, -0.5f, -0.5f), Vec2f(1, 1)),
        VertexInput(Vec3f( 0.5f,  0.5f, -0.5f), Vec2f(1, 1)),
        VertexInput(Vec3f(-0.5f,  0.5f, -0.5f), Vec2f(1, 1)),
    ];

    static GLuint[18] indices = [
        //front
        0, 1, 2, 2, 3, 0,
        ////back
        7, 4, 5, 5, 6, 7,
        4, 7, 6, 6, 5, 4
            ////right
            //1, 5, 6, 2,
            ////left
            //3, 6, 4, 0,
            ////top
            //3, 2, 7, 6,
            ////bottom
            //1, 0, 3, 4
    ];
}
