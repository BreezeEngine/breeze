module breeze.math.vector;
import std.stdio;
import std.traits;
import breeze.math.units;

static immutable enum float kindaSmallNumber = 0.000001f;


T[size] nullArray(T, size_t size)(){
    import std.range;
    import std.algorithm.mutation;
    T[size] data;
    repeat(0).take(size).copy(data[]);
    return data;
}

//unittest{
//    import std.algorithm: count;
//    assert(nullArray!(float,3)[].count(0) is 3);
//}
alias Vec2f = Vector!(float, 2);
alias Vec3f = Vector!(float, 3);

alias Vec2d = Vector!(double, 2);
alias Vec3d = Vector!(double, 3);

struct Vector(T, size_t _dimension){
    import breeze.math.units;

    static immutable dimension = _dimension;
    alias Type = T;

    private enum vectorCords = "xyzw";
    T[dimension] data = nullArray!(T, dimension);
    this(in T[dimension] ts...)
    {
        data = ts;
    }
    this(in T[dimension] ts)
    {
        data = ts;
    }

    auto ref opDispatch(string op)()
    if(op.length <= dimension){
        import std.range;
        import std.string: indexOf;
        import std.algorithm.iteration: map;
        static if(op.length == 1){
            enum index = vectorCords.indexOf(op);
            return data[index];
        }
        else{
            import std.algorithm.mutation: copy;
            import std.algorithm.searching: count;
            static immutable indices = op.map!(c => vectorCords.indexOf(c)).array;
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
    Vector opBinary(string op)(in Vector other) const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[dimension] _data;
        mixin ("zip(data[], other.data[]).map!(t => t[0]" ~ op ~ "t[1]).copy(_data[]);");
        return Vector!(T, dimension)(_data);
    }
    Vector opBinary(string op)(in T other) const{
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[dimension] _data;
        mixin ("data[].map!((val){return val" ~ op ~ "other;}).copy(_data[]);");
        return Vector!(T, dimension)(_data);
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
    static enum Vector zero(){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: fill;
        static import std.math;
        T[dimension] _data;
        fill(_data[],0);
        return Vector!(T, dimension)(_data);
    }
}
enum isVector(Vec) = __traits(isSame, TemplateOf!(Vec),Vector);

Vec zero(Vec)(){
    Vec.Type[Vec.dimension] data = nullArray!(Vec.Type, Vec.dimension);
    return Vec(data);
}
unittest{
    assert(zero!Vec2f.isZero);
}

bool isZero(Vec)(in Vec v, float tolerance = kindaSmallNumber){
    enum zeroVector = Vec.zero();
    return v.equals(zeroVector, kindaSmallNumber);
}
unittest{
    auto v1 = Vector!(float, 3)(0,0,0);
    assert(v1.isZero);
}
/*
  Calculates thedot product between to vectors.The return type is 'float'
*/
float dot(Vec)(in Vec v1, in Vec v2)
if(isVector!(Vec)){
    import std.exception: enforce;
    import std.range: zip;
    import std.algorithm.iteration;
    return zip(v1.data[], v2.data[]).map!(t => t[0] * t[1]).sum;
}
unittest{
    auto v1 = Vec2f(10,0);
    auto v2 = Vec2f(0,10);
    assert(dot(v1,v2) is 0);
    assert(dot(v1.unit ,v1.unit) is 1);
}

R length(R = float, Vec)(in Vec v){
    import std.math: sqrt;
    return sqrt(v.lengthSquared);
}

unittest{
    auto v1 = Vector!(float, 3)(2,2,1);
    assert(v1.length == 3);
}

float lengthSquared(Vec)(in Vec v)
if(isVector!(Vec)){
    import std.math: sqrt;
    return dot(v,v);
}

unittest{
    assert(Vec3f(2,2,2).lengthSquared is 12);
    assert(Vec3f(1,1,1).lengthSquared is 3);
    assert(Vec3f(0,0,0).lengthSquared is 0);
}

/**
  Projects vector a onto vector b with the property that the right angle will always be on
  vector b.
*/
Vec projectOnTo(Vec)(in Vec v1, in Vec v2){
    return v2 * (v1.dot(v2) / v2.lengthSquared);
}
/**
  Projects vector a onto vector b with the property that the right angle will always be on
  vector a.
*/
Vec inverseProjectOnTo(Vec)(in Vec v1, in Vec v2){
    auto otherUnit = v2.unit;
    auto cosAngle = dot(v1.unit, otherUnit);
    return otherUnit * v1.length / cosAngle;
}
unittest{
    import breeze.math.matrix;
    import breeze.math.units;
    import std.math;
    auto m = rotation2d(Radians(Degrees(45)));
    alias Vec2 = Vector!(float, 2);
    auto a = Vec2(10,0);
    auto b = m.mul(a).unit * 20;
    assert(a.dot(b - b.projectOnTo(a)) is 0);
    assert(b.dot(a - a.projectOnTo(b)) is 0);
}

Vec mirror(Vec)(in Vec m, in Vec normal){
    return m - normal * normal.dot(m) * 2;
}
unittest{
    alias Vec2 = Vector!(float, 2);
    auto v1 = Vec2(1,-1);
    //        assert(v1.mirror(Vec2(0,1)) is Vec2(1,1));
    //writeln(Vec2(0,1).mirror(Vec2(1,1).unit).equals(Vec2(-1,0)));
}

/**
  Checks if the vector is of length 1 by taking the difference of 1 - lengthSquared.
*/
bool isUnit(Vec)(in Vec v, float tolerance = kindaSmallNumber){
    import std.math: abs;
    auto length = v.lengthSquared;
    return abs(typeof(length)(1) - length) < tolerance;
}

unittest{
    assert(Vec2f(10,15).unit.isUnit);
}

Radians angle(Vec)(in Vec v1, in Vec v2) {
    import std.math: acos;
    //BUG REPORT linker error
    //return Radians(acos(v1.unit.dot(v2.unit)));
    return Radians(acos(dot(v1.unit, v2.unit)));
}

unittest{
    auto v1 = Vector!(float, 3)(1,0,0);
    auto v2 = Vector!(float, 3)(0,1,0);
    auto r = v1.angle(v2);
    assert(Degrees(v1.angle(v2)) is Degrees(90));
}

auto abs(Vec)(in Vec v){
    import std.range;
    import std.algorithm.iteration: map;
    import std.algorithm.mutation: copy;
    static import std.math;
    Vec.Type[Vec.dimension] _data;
    v.data[].map!(std.math.abs).copy(_data[]);
    return Vec(_data);
}

unittest{
    auto v1 = Vec2f(-1,-1);
    assert(v1.abs is Vec2f(1,1));
}

Vec unit(Vec)(in Vec v){
    return v / v.length;
}

unittest{
    auto v1 = Vec3f(10, 0, 0);
    assert(v1.unit is Vec3f(1,0,0));
}

float distance(Vec)(in Vec v1, in Vec v2){
    import std.math: sqrt;
    return length(v1 - v2);
}

unittest{
    auto v1 = Vec2f(2,2);
    auto v2 = Vec2f(4,2);
    assert(distance(v1, v2) is 2);
    assert(distance(v1, v2) is length(v1 - v2));
}

float distanceSquared(Vec)(in Vec v1, in Vec v2){
    import std.math: sqrt;
    return lengthSquared(v1 - v2);
}
unittest{
    auto v1 = Vec2f(2,2);
    auto v2 = Vec2f(4,2);
    assert(distanceSquared(v1, v2) is dot(v1 - v2, v1 - v2));
}

/**
      Compares two Vectors with a tolerance value
*/
bool equals(Vec)(in Vec v1, in Vec v2, float tolerance = kindaSmallNumber){
    import std.math;
    import std.range;
    import std.algorithm.iteration;
    return reduce!((a, b) => a && b)(true,
            zip(v1.data[], v2.data[]).map!(t => abs(t[0] - t[1]) < kindaSmallNumber));
}
unittest{
    auto v1 = Vector!(float, 3)(10, 0, 0);
    auto v2 = Vector!(float, 3)(10, 0, 0);
    assert(v1.equals(v2));
}

