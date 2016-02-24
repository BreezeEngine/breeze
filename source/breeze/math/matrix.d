module breeze.math.matrix;
import std.stdio;

import breeze.math.units;
auto rotation2d(Radians _angle){
    import breeze.math.vector;
    import std.math: cos, sin;
    alias Vec2 = Vector!(float,2);
    return Matrix!(float,2,2)(Vec2( cos(_angle.value), -sin(_angle.value)),
                              Vec2(sin(_angle.value), cos(_angle.value)));
}
//unittest{
//    import breeze.math.vector;
//    import std.math;
//    auto m = rotation2d(Radians(PI/2));
//    auto v = m.mul(Vector!(float,2)(1,0));
//    assert(v.equals(Vector!(float,2)(0,1)));
//}
struct Matrix(T, size_t rows, size_t colums){
    import breeze.math.vector: Vector;
    Vector!(T,colums)[rows] data;

    static if(colums == rows){
        static enum identity() {
            auto mat = Matrix!(T,colums,colums)();
            foreach(index; 0..colums){
                mat.data[index].data[index] = 1;
            }
            return mat;
        }
    }
    this(in Vector!(T,colums)[rows] _data...){
        data = _data;
    }
    Matrix!(T, colums, rows) transpose() const{
        Vector!(T,rows)[colums] _data;
        foreach(j; 0..rows){
            foreach(i; 0..colums){
                _data[i].data[j] = data[j].data[i];
            }
        }
        return typeof(return)(_data);
    }
    auto mul(in Vector!(T, colums) other) const{
        auto m = Matrix!(T,1,colums)(other);
        auto trans = m.transpose;
        auto rm = this.mul(trans).transpose;
        return rm.data[0];
    }
    auto mul(size_t oRows, size_t oColums)(in Matrix!(T, oRows, oColums) other) const{
        import breeze.math.vector: dot;
        static assert(colums == oRows, "Assert: " ~ colums.stringof ~ " != " ~ oRows.stringof);
        Vector!(T,oColums)[rows] _data;
        auto otherTransposed = other.transpose;
        foreach(j; 0..rows){
            foreach(i; 0..oColums){
                _data[j].data[i] = dot(data[j], otherTransposed.data[i]);
            }
        }
        return Matrix!(T,rows,oColums)(_data);
    }

}
unittest{
    import breeze.math.vector;
    auto id = Matrix!(float,3,3).identity();
    alias Vec2 = Vector!(float,2);
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(Vec3(1, 2, 3),
                                 Vec3(4, 5, 6),
                                 Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,2)(Vec2(1, 4),
                                 Vec2(2, 5),
                                 Vec2(3, 6));
    assert(m.mul(id) is m);
}
unittest{
    import breeze.math.vector;
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(Vec3(1, 2, 3),
            Vec3(4, 5, 6),
            Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,3)(Vec3(1, 4, 7),
            Vec3(2, 5, 8),
            Vec3(3, 6, 9));
    assert(m.transpose is m2);
}
unittest{
    import breeze.math.vector;
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(Vec3(1, 2, 3),
            Vec3(4, 5, 6),
            Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,3)(Vec3(1, 4, 7),
            Vec3(2, 5, 8),
            Vec3(3, 6, 9));
    assert(m.transpose is m2);
}
unittest{
    import breeze.math.vector;
    alias Vec3 = Vector!(float,3);
    alias Vec2 = Vector!(float,2);
    auto m = Matrix!(float,2,3)(Vec3(1, 2, 3),
            Vec3(4, 5, 6));
    auto m2 = Matrix!(float,3,2)(Vec2(1, 4),
            Vec2(2, 5),
            Vec2(3, 6));
    assert(m.transpose is m2);
}
