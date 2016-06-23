module breeze.util.obj;

public struct Mesh{
    import breeze.math.vector;
    Vec3f position;
    Vec3f normal;
    Vec2f uv;
}
auto parsObj(string path){
    import breeze.math.vector;
    import std.stdio;
    import std.string;
    import std.conv;
    import breeze.util.array;

    Array!Vec3f vertices;
    Array!Vec3f normals;
    Array!Vec2f uvs;

    Array!int vertexIndices;
    Array!int normalIndices;
    Array!int uvIndices;

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
                if(r.length is 3){
                    foreach(e; r){
                        vertexIndices.insert(e[0]);
                        uvIndices.insert(e[1]);
                        normalIndices.insert(e[2]);
                    }
                }
                else if(r.length is 4){
                    alias f = (range){
                        foreach(index; range){
                            vertexIndices.insert(r[index][0]);
                            uvIndices.insert(r[index][1]);
                            normalIndices.insert(r[index][2]);
                        }
                    };
                    f([0, 1, 2]);
                    f([0, 2, 3]);
                }

            }
            else if(first == "vt"){
                import std.algorithm.iteration;
                import std.algorithm.mutation: copy;
                float[2] data;
                arr[1..$].map!(s => s.to!float)[0 .. 2].copy(data[]);
                uvs.insert(Vec2f(data));
            }
        }
    }
    Array!Mesh mesh;
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
