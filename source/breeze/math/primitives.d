module breeze.math.primitives;
import breeze.math.vector;
import std.stdio;
struct Polygon(T, size_t size){
    Vector!(T,2)[size] data;
}

struct AABB{
    import breeze.math.vector;
    Vec2f lower;
    Vec2f upper;

    this(Vec2f lower, Vec2f upper){
        this.lower = lower;
        this.upper = upper;
    }

    void translate(Vec2f v){
        lower = lower + v;
        upper = upper + v;
    }
}

bool overlap(in AABB a, in AABB b){
    if( a.upper.x < b.lower.x || b.upper.x < a.lower.x){
        return false;
    }
    if( a.upper.y < b.lower.y || b.upper.y < a.lower.y){
        return false;
    }
    return true;
}
bool contains(in AABB a, in AABB b){
    if(a.lower.x <= b.lower.x && b.upper.x <= a.upper.x &&
       a.lower.y <= b.lower.y && b.upper.y <= a.upper.y){
        return true;
    }
    return false;
}

float perimeter(in AABB a){
    float wx = a.upper.x - a.lower.x;
    float wy = a.upper.y - a.lower.y;
    return 2.0 * (wx + wy);
}

AABB combine(in AABB a, in AABB b){
    import breeze.math.util;
    import breeze.math.vector;
    Vec2f lower = min(a.lower, b.lower);
    Vec2f upper = min(a.upper, b.upper);
    return AABB(lower, upper);
}
Vec2f center(in AABB a){
    return (a.lower + a.upper) * 0.5;
}
unittest{
    import breeze.math.vector;
    auto a = AABB(Vec2f(0,0), Vec2f(100,100));
    auto b = AABB(Vec2f(10,10), Vec2f(50,50));
}
unittest{
    import breeze.math.vector;
    auto a = AABB(Vec2f(0,0), Vec2f(1,1));
    auto a1 = AABB(Vec2f(0,-1), Vec2f(1,-0.9));
}
