module breeze.math.vector;
import std.stdio;
import std.traits;
import breeze.math.units;
import breeze.math.constants;

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
alias Vec4f = Vector!(float, 4);

alias Vec2d = Vector!(double, 2);
alias Vec3d = Vector!(double, 3);

alias Vec2i = Vector!(int, 2);

struct UnitVector(T, size_t _dimension){
    Vector!(T, _dimension) vector;
    alias vector this;
}
auto unit2(Vec)(Vec v){
    auto length = v.length;
    assert(v.length !is 0);
    return UnitVector!(Vec.Type, Vec.dimension)(v / length);
}
unittest{
    auto v = unit2(Vec3f(2, 0, 0));
}
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

    static if(dimension > 1){
        import std.algorithm.mutation;
        this(Vector!(T, dimension - 1) v, T value){
            data = v.data ~ value;
        }
    }

    ref auto opDispatch(string op)() inout
    if(op.length is 1){
        import std.string: indexOf;
        import std.algorithm.iteration: map;
        enum index = vectorCords.indexOf(op);
        return data[index];
    }
    auto opDispatch(string op)() const
    if(op.length > 1 && op.length <= dimension){
        import std.string: indexOf;
        import std.algorithm.iteration: map;
        import std.range: array;
        import std.algorithm.mutation: copy;
        import std.algorithm.searching: count;
        static immutable indices = op.map!(c => vectorCords.indexOf(c)).array;
        static assert(indices[].count(-1) == 0, "Combination of " ~op~" does not exist.");
        T[op.length] _data;
        indices.map!(i => data[i]).copy(_data[]);
        return Vector!(T,op.length)(_data);
    }

    unittest{
        auto v1 = Vector!(float, 4)(1, 2, 3, 4);
        assert(v1.x is 1);
        assert(v1.y is 2);
        assert(v1.z is 3);
        assert(v1.w is 4);

        assert(v1.xy is Vector!(float, 2)(1,2));
        assert(v1.xyzw is v1);

        //        v1.x = 42;
        //        assert(v1.x is 42);
    }

    Vector opBinary(string op)(const Vector other) const{
        import std.range: zip;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: copy;
        T[dimension] _data;
        mixin ("zip(data[], other.data[]).map!(t => t[0]" ~ op ~ "t[1]).copy(_data[]);");
        return Vector!(T, dimension)(_data);
    }

    Vector opBinary(string op)(const T other) const{
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

    Vector opUnary(string op)() inout
    if(op is "-"){
        return this * -1;
    }

    static enum Vector zero(){
        import std.range;
        import std.algorithm.iteration: map;
        import std.algorithm.mutation: fill;
        T[dimension] _data;
        fill(_data[],0);
        return Vector!(T, dimension)(_data);
    }
    string toString(){
      string s = "Vec(";
      import std.range;
      import std.algorithm.iteration;
      import std.conv;
      return "Vec(" ~ data[].map!(val => val.to!string).join(", ") ~ ")";
    }
}

unittest{
    auto v1 = Vec2f(1, 0);
    auto v2 = Vec3f(v1, 1);
    assert(v2 is Vec3f(1, 0, 1));
}
enum isVector(Vec) = __traits(isSame, TemplateOf!(Vec),Vector);

Vec zero(Vec)(){
    Vec.Type[Vec.dimension] data = nullArray!(Vec.Type, Vec.dimension);
    return Vec(data);
}

unittest{
    assert(zero!Vec2f.isZero);
}

bool isZero(Vec)(const Vec v, float tolerance = kindaSmallNumber){
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
auto dot(Vec)(const Vec v1, const Vec v2)
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

auto length(Vec)(const Vec v)
if(isVector!(Vec)){
    import std.math: sqrt;
    return sqrt(v.lengthSquared);
}

unittest{
    auto v1 = Vector!(float, 3)(2,2,1);
    assert(v1.length == 3);
}

auto lengthSquared(Vec)(const Vec v)
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
Vec projectOnTo(Vec)(const Vec v1, const Vec v2){
    return v2 * (v1.dot(v2) / v2.lengthSquared);
}

/**
  Projects vector a onto vector b with the property that the right angle will always be on
  vector a.
*/
Vec inverseProjectOnTo(Vec)(const Vec v1, const Vec v2){
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

Vec reflect(Vec)(const Vec m, const Vec normal){
    return m - normal * normal.dot(m) * 2;
}

unittest{
    alias Vec2 = Vector!(float, 2);
    assert(Vec2f(1,-1).reflect(Vec2(0,1)).equals(Vec2f(1,1)));
    assert(Vec2f(0,-1).reflect(Vec2f(1,1).unit).equals(Vec2f(1,0)));
    assert(Vec2f(-1,0).reflect(Vec2f(1,0)).equals(Vec2f(1,0)));
}

/**
  Checks if the vector is of length 1 by taking the difference of 1 - lengthSquared.
*/
bool isUnit(Vec)(const Vec v, float tolerance = kindaSmallNumber){
    import std.math: abs;
    auto length = v.lengthSquared;
    return abs(typeof(length)(1) - length) < tolerance;
}

unittest{
    assert(Vec2f(10,15).unit.isUnit);
}

Radians angle(Vec)(const Vec v1, const Vec v2) {
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

auto abs(Vec)(const Vec v){
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

Vec unit(Vec)(const Vec v){
    auto length = v.length;
    assert(v.length !is 0);
    return v / length;
}

unittest{
    auto v1 = Vec3f(10, 0, 0);
    assert(v1.unit is Vec3f(1,0,0));
}

Vec safeUnit(Vec)(const Vec v){
    auto lengthSq = v.lengthSquared;
    if(lengthSq is 1){
        return v;
    }
    else if(lengthSq < 1){
        return Vec.zero;
    }
    return v.unit;
}

unittest{
    assert(Vec2f.zero.safeUnit is Vec2f.zero);
}

float distance(Vec)(const Vec v1, const Vec v2){
    import std.math: sqrt;
    return length(v1 - v2);
}

unittest{
    auto v1 = Vec2f(2,2);
    auto v2 = Vec2f(4,2);
    assert(distance(v1, v2) is 2);
    assert(distance(v1, v2) is length(v1 - v2));
}

float distanceSquared(Vec)(const Vec v1, const Vec v2){
    import std.math: sqrt;
    return lengthSquared(v1 - v2);
}

unittest{
    auto v1 = Vec2f(2,2);
    auto v2 = Vec2f(4,2);
    assert(distanceSquared(v1, v2) is dot(v1 - v2, v1 - v2));
}

/**
      Compares two vectors with a tolerance value, if the type of the vector
      is a floating pointer number.
*/
bool equals(Vec, T = Vec.Type)(const Vec v1, const Vec v2, T tolerance = kindaSmallNumber)
if(isVector!Vec && isFloatingPoint!(Vec.Type)){
    import std.math: abs;
    import breeze.meta: zip;
    import std.algorithm.iteration: map;
    import std.algorithm.searching: all;
    return zip(v1.data[], v2.data[]).map!(t => abs(t[0] - t[1]) < kindaSmallNumber).all;
}

unittest{
    auto v1 = Vector!(float, 3)(10, 0, 0);
    auto v2 = Vector!(float, 3)(10, 0, 0);
    assert(v1.equals(v2));
}

bool equals(Vec)(const Vec v1, const Vec v2)
if(isVector!Vec && isIntegral!(Vec.Type)){
    import breeze.meta: zip;
    import std.algorithm.iteration: map;
    import std.algorithm.searching: all;
    return zip(v1.data[], v2.data[]).map!(t => t[0] is t[1]).all;
}

unittest{
    auto v1 = Vec2i(1,2);
    assert(v1.equals(v1));
}

Vec cross(Vec)(const Vec v1, const Vec v2)
if(isVector!Vec && Vec.dimension is 3){
    return Vec(v1.y * v2.z - v1.z * v2.y,
               v1.z * v2.x - v1.x * v2.z,
               v1.x * v2.y - v1.y * v2.x);
}

unittest{
    auto v1 = Vec3f(1, 0, 0);
    auto v2 = Vec3f(0, 1, 0);
    assert(v1.cross(v2) is Vec3f(0, 0, 1));
}
