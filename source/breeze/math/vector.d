module breeze.math.vector;
import std.stdio;


static immutable float kindaSmallNumber = 0.0000001f; 
struct Degrees{
    float value;
    alias value this;
    this(float value){
        this.value = value;
    }
    this(Radians r){
        import std.math: PI;
        value = r.value * 360.0f / (2*PI);
    }
}
struct Radians{
    float value;
    alias value this;
    this(float value){
        this.value = value;
    }
    this(Degrees d){
        import std.math: PI;
        value = d.value * (2*PI) / 360.0f;
    }
}
unittest{
    import std.conv;
    import std.math;
    auto d = Degrees(180);
    auto r = to!Radians(d);
    assert(to!Radians(Degrees(180)) == Radians(PI));
    assert(to!Radians(Degrees(90)) == Radians(PI/2));
    assert(to!Degrees(Radians(PI)) == Degrees(180));
    assert(to!Degrees(Radians(PI/2)) == Degrees(90));
}

struct Vector(T, size_t size){
    T[size] data;
    this(T[size] ts...)
    {
        data = ts;
    }
    float dot(const ref this other){
        import std.range;
        import std.algorithm.iteration;
        return zip(data[], other.data[]).map!(t => t[0] * t[1]).sum;
    }
    float length(){
        import std.math: sqrt;
        return sqrt(dot(this));
    }
    Vector opBinary(string op)(const auto ref Vector other){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[size] _data;
        mixin ("zip(data[], other.data[]).map!(t => t[0]" ~ op ~ "t[1]).copy(_data[]);");
        return Vector!(T, size)(_data);
    }
    Vector opBinary(string op)(const auto ref T other){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[size] _data;
        mixin ("data[].map!(val => val" ~ op ~ "other).copy(_data[]);");
        return Vector!(T, size)(_data);
    }
    Vector unit(){
        return this / length;
    }
    float distance()(const auto ref Vector other){
        import std.math: sqrt;
        return sqrt(dot(other));
    }
    bool equals()(const auto ref Vector other, float tolerance = kindaSmallNumber){
        import std.math;
        import std.range;
        import std.algorithm.iteration;
        return zip(data[], other.data[]).map!(t => abs(t[0] - t[1]) < kindaSmallNumber).reduce!((a, b) => a && b);
    }
    Vector abs(){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        static import std.math;
        T[3] _data;
        data[].map!(std.math.abs).copy(_data[]);
        return Vector!(T, size)(_data);
    }
    static Vector zero(){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: fill;
        static import std.math;
        T[3] _data;
        fill(_data[],0);
        return Vector!(T, size)(_data);
    }

    bool isZero(float tolerance = kindaSmallNumber){
        enum zeroVector = Vector.zero();
        return equals(zeroVector, kindaSmallNumber);
    }
}
unittest{
    auto v1 = Vector!(float, 3)(2,2,1);
    assert(v1.length == 3);
}
unittest{
    auto v1 = Vector!(float, 3)(1, 2, 3);
    auto v2 = Vector!(float, 3)(4, 5, 6);

    auto v3 = v1 - v2;
    assert(v3 is Vector!(float, 3)(-3, -3, -3));

    auto v4 = v1 + v2;
    assert(v4 is Vector!(float, 3)(5,7,9));

    auto v5 = v1 + 1.0f;
    assert(v5 is Vector!(float, 3)(2,3,4));
}

unittest{
    auto v1 = Vector!(float, 3)(10, 0, 0);
    assert(v1.unit is Vector!(float, 3)(1,0,0));
}
unittest{
    auto v1 = Vector!(float, 3)(10, 0, 0);
    auto v2 = Vector!(float, 3)(10, 0, 0);
    assert(v1.equals(v2));
}

unittest{
    auto v1 = Vector!(float, 3)(0,0,0);
    assert(v1.isZero);
}
