module breeze.math.quaternion;

import std.stdio;
import breeze.math.vector;
import breeze.math.units;
struct UQuaternion(T){
    Quaternion!T q;
    alias q this;
    this(Vector!(T, 3) axis, Radians angle){
        import std.math: sin, cos;
        auto halfAngle = (angle.value / 2.0f);
        v = axis.unit * sin(halfAngle);
        w = cos(halfAngle);
    }
}
struct Quaternion(T){
    import std.traits: isFloatingPoint;
    static assert(isFloatingPoint!T, "Quaternion only accepts a floating point type");
    T w;
    Vector!(T, 3) v;

    this(T w, Vector!(T, 3) v){
        this.w = w;
        this.v = v;
    }

    Quaternion opBinary(string op)(const float other) const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        float newW = mixin("w " ~ op ~ " other");
        Vec3f newV = mixin("v " ~ op ~ " other");
        return Quaternion(newW, newV);
    }

    Quaternion mul(const Quaternion other){
        float newW = w * other.w - dot(v, other.v);
        Vec3f newV = (other.v * w) + (v * other.w) + cross( v, other.v );
        auto q = Quaternion(newW, newV);
        return q / q.length;
    }
    Vec3f mul(Vec3f other){
        auto p = Quaternion(0, other);
        auto inverseQ = this.conjugate;
        return (this.mul(p).mul(inverseQ)).v;
    }
}
//unittest{
//    import std.random;
//    import std.range;
//    Random gen;
//    auto q1 = Quaternion(Vec3f(1, 0, 0), Degrees(90));
//    foreach(_; iota(0, 100000000)){
//        float x = uniform(0.0f, 1.0f, gen);
//        float y = uniform(0.0f, 1.0f, gen);
//        float z = uniform(0.0f, 1.0f, gen);
//        q1 = q1.mul(Quaternion(Vec3f(x, y, z), Degrees(uniform(0, 360, gen))));
//    }
//    writeln("length", q1.length);
//
//}
unittest{
    auto q1 = UQuaternion!float(Vec3f(1, 0, 0), Degrees(90));
    auto q2 = UQuaternion!float(Vec3f(0, 1, 0), Degrees(90));
    auto q3 = q2.mul(q1);

    auto v = Vec3f(0, 1, 0);
    writeln(q1.mul(v));
}
//
//unittest{
//    auto q1 = Quaternion(Vec3f(1, 0, 0), Degrees(90));
//    auto q2 = Quaternion(Vec3f(0, 1, 0), Degrees(90));
//    writeln(q2.mul(q1));
//}
//
auto inverse(T)(const Quaternion!T quat){
    return quat.conjugate / quat.magnitude;
}
auto inverse(T)(const UQuaternion!T quat){
    return quat.conjugate;
}
//unittest{
//    auto q1 = Quaternion(Vec3f(1, 0, 0), Degrees(90));
//    writeln(q1.length);
//    auto q2 = q1.inverse;
//    writeln(q2.length);
//}
//
auto conjugate(T)(const Quaternion!T quat){
    return Quaternion!T(quat.w, -quat.v);
}

auto conjugate(T)(const UQuaternion!T quat){
    return UQuaternion!T(quat.w, -quat.v);
}

//
T magnitude(T)(const Quaternion!T quat){
    return quat.w * quat.w + quat.v.lengthSquared;
}

T magnitude(T)(const UQuaternion!T quat){
    return cast(T)1.0f;
}
//
unittest{
    import std.math;
    auto q1 = UQuaternion!float(Vec3f(1, 0, 0), Degrees(90));
    assert(q1.magnitude.approxEqual(1.0f));
}

auto length(T)(const Quaternion!T quat){
    import std.math: sqrt;
    return sqrt(quat.magnitude);
}

T length(T)(const UQuaternion!T quat){
    return cast(T)1.0f;
}
//
//unittest{
//    import std.math;
//    auto q1 = Quaternion(Vec3f(1, 0, 0), Degrees(90));
//    assert(q1.length.approxEqual(1.0f));
//}
