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

unittest{
    import breeze.math.vector;
    import std.math;
    auto m = rotation2d(Radians(PI/2));
    auto m1 = rotation2d(Degrees(45));
    auto v = m * Vec2f(1,0);
    assert(v.equals(Vector!(float,2)(0,1)));
}

struct Matrix(T, size_t _rows, size_t _colums){
    import breeze.math.vector: Vector;

    alias Type = T;
    static immutable rows = _rows;
    static immutable colums = _colums;
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
    auto opBinary(string op)(in Matrix other)
    if(op is "*"){
        return mul(other);
    }
    auto opBinary(string op)(in Vector!(T, colums) other)
    if(op is "*"){
        return mul(other);
    }
}

/*
    Orthographic projection
*/

Matrix!(float, 4, 4) ortho(float left, float right, float bottom, float top, float near, float far){
    import breeze.math.vector: Vec4f;
    return Matrix!(float, 4, 4)(
            Vec4f(2/(right - left), 0, 0, -(right + left)/(right - left)),
            Vec4f(0, 2/(top - bottom), 0, -(top + bottom)/(top - bottom)),
            Vec4f(0, 0, -2/(far - near),  -(far + near)/(far - near)),
            Vec4f(0, 0, 0, 1)
    );
}
unittest{
    import breeze.math.vector;
    auto v = ortho(-10, 10, -10, 10, -1, 1) * Vec4f(10, 10, 10, 0);
}

auto transpose(Mat)(in Mat m){
    import breeze.math.vector;
    Vector!(Mat.Type, Mat.rows)[Mat.colums] _data;
    foreach(j; 0..Mat.rows){
        foreach(i; 0..Mat.colums){
            _data[i].data[j] = m.data[j].data[i];
        }
    }
    return Matrix!(Mat.Type, Mat.colums, Mat.rows)(_data);
}

unittest{
    import breeze.math.vector;
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(
            Vec3(1, 2, 3),
            Vec3(4, 5, 6),
            Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,3)(
            Vec3(1, 4, 7),
            Vec3(2, 5, 8),
            Vec3(3, 6, 9));
    auto m3 = m * m2;
    assert(m.transpose is m2);
}

unittest{
    import breeze.math.vector;
    auto id = Matrix!(float,3,3).identity();
    alias Vec2 = Vector!(float,2);
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(
            Vec3(1, 2, 3),
            Vec3(4, 5, 6),
            Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,2)(
            Vec2(1, 4),
            Vec2(2, 5),
            Vec2(3, 6));
    assert(m.mul(id) is m);
    assert(m * id is m);
}

unittest{
    import breeze.math.vector;
    alias Vec3 = Vector!(float,3);
    auto m  = Matrix!(float,3,3)(
            Vec3(1, 2, 3),
            Vec3(4, 5, 6),
            Vec3(7, 8, 9));

    auto m2 = Matrix!(float,3,3)(
            Vec3(1, 4, 7),
            Vec3(2, 5, 8),
            Vec3(3, 6, 9));
    assert(m.transpose is m2);
}

unittest{
    import breeze.math.vector;
    auto m = Matrix!(float,2,3)(
            Vec3f(1, 2, 3),
            Vec3f(4, 5, 6));
    auto m2 = Matrix!(float,3,2)(
            Vec2f(1, 4),
            Vec2f(2, 5),
            Vec2f(3, 6));
    assert(m.transpose is m2);
}
