module breeze.util.obj;

public struct Mesh{
    import breeze.math.vector;
    Vec3f position;
    Vec3f normal;
    Vec2f uv;
}
auto parsObj(string path){
    import containers.dynamicarray;
    import breeze.math.vector;
    import std.stdio;
    import std.string;
    import std.conv;

    DynamicArray!Vec3f vertices;
    DynamicArray!Vec3f normals;
    DynamicArray!Vec2f uvs;

    DynamicArray!int vertexIndices;
    DynamicArray!int normalIndices;
    DynamicArray!int uvIndices;

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
                vertices.insert(Vec3f(data));
            }
            if(first == "vn"){
                import std.algorithm.iteration;
                import std.algorithm.mutation: copy;
                float[3] data;
                arr[1..$].map!(s => s.to!float).copy(data[]);
                normals.insert(Vec3f(data));
            }
            else if(first == "f"){
                import std.algorithm.iteration;
                auto r = arr[ 1 .. $].map!(s => s.split("/"))
                                     .map!(a => a.map!(s => to!int(s) - 1));
                foreach(e; r){
                    vertexIndices.insert(e[0]);
                    uvIndices.insert(e[1]);
                    normalIndices.insert(e[2]);
                }

            }
            else if(first == "vt"){
                import std.algorithm.iteration;
                import std.algorithm.mutation: copy;
                float[2] data;
                arr[1..$].map!(s => s.to!float).copy(data[]);
                uvs.insert(Vec2f(data));
            }
        }
    }
    DynamicArray!Mesh mesh;
    import std.range;

    foreach(index; iota(0, vertexIndices.length)){
        mesh.insert(Mesh(vertices[vertexIndices[index]]
                        ,normals[normalIndices[index]]
                        ,uvs[uvIndices[index]]));
    }
    return mesh;
}

unittest{
    import std.stdio;
    //auto obj = Obj("/home/maik/projects/breeze/test.obj");
}
