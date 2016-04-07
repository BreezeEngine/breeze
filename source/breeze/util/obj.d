module breeze.util.obj;

struct Obj{
    import breeze.math.vector;
    import std.container: Array;
    Array!Vec3f vertices;
    Array!Vec3f normals;
    Array!Vec2f uvs;
    Array!int indices;

    this(string path){
        import std.stdio;
        import std.string;
        import std.conv;
        auto objFile = new File(path, "r");
        foreach(line; objFile.byLine){
            auto arr = split(line);
            if(arr.length > 0){
                auto first = arr[0];
                if(first == "v"){
                    import std.algorithm.iteration;
                    import std.algorithm.mutation: copy;
                    float[3] data;
                    arr[1..$].map!(s => s.to!float).copy(data[]);
                    vertices.insertBack(Vec3f(data));
                }
                if(first == "vn"){
                    import std.algorithm.iteration;
                    import std.algorithm.mutation: copy;
                    float[3] data;
                    arr[1..$].map!(s => s.to!float).copy(data[]);
                    normals.insertBack(Vec3f(data));
                }
                else if(first == "f"){
                    import std.algorithm.iteration;
                    auto r = arr[ 1 .. $].map!(s => s.split("/")).map!(a => a.map!(s => to!int(s) - 1));
                    foreach(e; r){
                        indices.insertBack(e[0]);
                    }

                }
                else if(first == "vt"){
                    import std.algorithm.iteration;
                    import std.algorithm.mutation: copy;
                    float[2] data;
                    arr[1..$].map!(s => s.to!float).copy(data[]);
                    uvs.insertBack(Vec2f(data));
                }
            }
        }
    }
}
unittest{
    import std.stdio;
    //auto obj = Obj("/home/maik/projects/breeze/test.obj");
}
