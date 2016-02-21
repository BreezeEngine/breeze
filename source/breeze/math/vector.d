module breeze.math.vector;
import std.stdio;

import std.range;
import std.range.primitives;
static immutable enum float kindaSmallNumber = 0.0000001f;
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


T[size] nullArray(T, size_t size)(){
    import std.range;
    import std.algorithm.mutation;
    T[size] data;
    repeat(0).take(size).copy(data[]);
    return data;
}

unittest{
    import std.algorithm: count;
    assert(nullArray!(float,3)[].count(0) is 3);
}

struct Vector(T, size_t size){
    private enum vectorCords = "xyzw";
    import std.range;
    T[size] data = nullArray!(T, size);
    this(in T[size] ts...)
    {
        data = ts;
    }
    this(in T[size] ts)
    {
        data = ts;
    }
    auto ref opDispatch(string op)()
    if(op.length <= size){
        import std.string: indexOf;
        import std.algorithm.iteration: map;
        static if(op.length == 1){
            enum index = vectorCords.indexOf(op);
            return data[index];
        }
        else{
            import std.algorithm.mutation: copy;
            import std.algorithm.searching: count;
            enum indices = op.map!(c => vectorCords.indexOf(c)).array;
            static assert(indices[].count(-1) == 0, "Combination of " ~op~" does not exist.");
            T[op.length] _data;
            indices.map!(i => data[i]).copy(_data[]);
            return Vector!(T,op.length)(_data);
        }
    }
    unittest{
        auto v1 = Vector!(float, 4)(1, 2, 3, 4);
        assert(v1.x is 1);
        assert(v1.y is 2);
        assert(v1.z is 3);
        assert(v1.w is 4);

        assert(v1.xy is Vector!(float, 2)(1,2));
        assert(v1.xyzw is v1);

        v1.x = 42;
        assert(v1.x is 42);
    }
    float dot(in Vector other) const{
        import std.range: zip;
        import std.algorithm.iteration;
        return zip(data[], other.data[]).map!(t => t[0] * t[1]).sum;
    }
    float length() const{
        import std.math: sqrt;
        return sqrt(dot(this));
    }
    unittest{
        auto v1 = Vector!(float, 3)(2,2,1);
        assert(v1.length == 3);
    }
    Vector opBinary(string op)(in Vector other) const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[size] _data;
        mixin ("zip(data[], other.data[]).map!(t => t[0]" ~ op ~ "t[1]).copy(_data[]);");
        return Vector!(T, size)(_data);
    }
    Vector opBinary(string op)(in T other) const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[size] _data;
        mixin ("data[].map!((val){return val" ~ op ~ "other;}).copy(_data[]);");
        return Vector!(T, size)(_data);
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
    Vector unit() const{
        return this / length;
    }
    unittest{
        auto v1 = Vector!(float, 3)(10, 0, 0);
        assert(v1.unit is Vector!(float, 3)(1,0,0));
    }

    float distance(in Vector other) const{
        import std.math: sqrt;
        return sqrt(dot(other));
    }
    /**
      Compares two Vectors with a tolerance value
    */
    bool equals(in Vector other, float tolerance = kindaSmallNumber) const{
        import std.math;
        import std.range;
        import std.algorithm.iteration;
        return zip(data[], other.data[]).map!(t => abs(t[0] - t[1]) < kindaSmallNumber)
        .reduce!((a, b) => a && b);
    }
    unittest{
        auto v1 = Vector!(float, 3)(10, 0, 0);
        auto v2 = Vector!(float, 3)(10, 0, 0);
        assert(v1.equals(v2));
    }
    /**
      Returns a Vector with the absolute values of its elements.
    */
    Vector abs() const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        static import std.math;
        T[size] _data;
        data[].map!(std.math.abs).copy(_data[]);
        return Vector!(T, size)(_data);
    }

    /++
    Calculates the rangle between two vectors. The result is in Radians.
    +/
    Radians angle(in Vector other) const{
        import std.math: acos;
        auto v1 = this.unit;
        auto v2 = other.unit;
        return Radians(acos(v1.dot(v2)));
    }
    unittest{
        auto v1 = Vector!(float, 3)(1,0,0);
        auto v2 = Vector!(float, 3)(0,1,0);
        assert(Degrees(v1.angle(v2)) is Degrees(90));
    }

    bool isUniform(float tolerance = kindaSmallNumber){
        return true;
    }
    static enum Vector zero(){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: fill;
        static import std.math;
        T[size] _data;
        fill(_data[],0);
        return Vector!(T, size)(_data);
    }

    bool isZero(float tolerance = kindaSmallNumber) const{
        enum zeroVector = Vector.zero();
        return equals(zeroVector, kindaSmallNumber);
    }
    unittest{
        auto v1 = Vector!(float, 3)(0,0,0);
        assert(v1.isZero);
    }
    bool parallel(in Vector other, Radians cosineThreshold = Radians(kindaSmallNumber)) const{
        //return this.angle(other)  
        return true;
    }
}


