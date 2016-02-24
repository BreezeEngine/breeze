module breeze.math.units;
import std.stdio;
struct Degrees{
    float value;
    this(in float value){
        this.value = value;
    }
    this(Radians r){
        import std.math: PI;
        value = r.value * 360.0f / (2*PI);
    }
    auto opBinary(string op)(in Degrees other){
         return Degrees(mixin("value" ~ op ~ "other.value"));
    }
    auto opBinary(string op)(in Radians other){
         return Degrees(mixin("value" ~ op ~ "Degrees(other).value"));
    }
    void opOpAssign(string op, T)(in T other)
    if(is(T == Radians) || is(T == Degrees)){
        value = this.opBinary!op(other).value;
    }
}

struct Radians{
    float value;
    this(float value){
        this.value = value;
    }
    this(Degrees d){
        import std.math: PI;
        value = d.value * (2*PI) / 360.0f;
    }
    auto opBinary(string op)(in Radians other){
         return Radians(mixin("value" ~ op ~ "other.value"));
    }
    auto opBinary(string op)(in Degrees other){
         return Radians(mixin("value" ~ op ~ "Radians(other).value"));
    }
    void opOpAssign(string op, T)(in T other)
    if(is(T == Radians) || is(T == Degrees)){
        value = this.opBinary!op(other).value;
    }
}

unittest{
    import std.conv;
    import std.math;
    auto r1 = Radians(PI);
    r1 += Degrees(180);
    assert(r1 is Radians(2*PI));

    auto d1 = Degrees(60);
    d1 += Degrees(300);
    d1 -= Degrees(180);
    assert(d1 is Degrees(180));
}
unittest{
    import std.conv;
    import std.math;
    assert(Degrees(90) + Degrees(90) == Degrees(180));
    assert(Degrees(90) + Radians(PI/2) == Degrees(180));
    assert(Radians(PI) + Degrees(180) == Radians(2*PI));
}
unittest{
    import std.conv;
    import std.math;
    assert(to!Radians(Degrees(180)) == Radians(PI));
    assert(to!Radians(Degrees(90)) == Radians(PI/2));
    assert(to!Degrees(Radians(PI)) == Degrees(180));
    assert(to!Degrees(Radians(PI/2)) == Degrees(90));
}
