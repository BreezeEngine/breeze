module breeze.math.util;
import std.stdio;
import breeze.math.vector;
static import std.math;

T interpolate(T)(in T a, in T b, float alpha){
    return a * (1 - alpha) + b * alpha;
}

auto componentMap(alias f, Vec...)(in Vec v){
    import breeze.meta;
    import std.range: zip;
    import std.algorithm.iteration;
    static import std.algorithm.comparison;
    import std.algorithm.mutation: copy;
    Vec[0].Type[Vec[0].dimension] _data;
    unpack!((ref a) => a.data[]).into!(zip)(v).map!((t) => f(t[0],t[1])).copy(_data[]);
    return Vec[0](_data);
}

auto min(Vec...)(in Vec v){
    static import std.algorithm.comparison;
    return componentMap!(std.algorithm.comparison.min)(v);
}
auto max(Vec...)(in Vec v){
    static import std.algorithm.comparison;
    return componentMap!(std.algorithm.comparison.max)(v);
}
unittest{
    auto v1 = Vec2f(5.0,10.0);
    auto v2 = Vec2f(1.0,12.0);
    assert(min(v1, v2) is Vec2f(1.0, 10.0));
}

unittest{
    float f1 = 2;
    float f2 = 4;
    assert(interpolate(f1, f2, 0.5) is 3);
    assert(interpolate(f1, f2, 0.0) is f1);
    assert(interpolate(f1, f2, 1.0) is f2);
}
unittest{
    import breeze.math.vector;
    auto v1 = Vec2f(2,2);
    auto v2 = Vec2f(4,4);
    assert(interpolate(v1, v2, 0.5).equals(Vec2f(3,3)));
    assert(interpolate(v1, v2, 0.0).equals(v1));
    assert(interpolate(v1, v2, 1.0).equals(v2));
}
