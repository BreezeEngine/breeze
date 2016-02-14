import std.stdio;
struct Position{
    float x,y,z;
}
struct Velocity{
    float x,y,z;
}
struct Player{
    string name;
}

struct PrintPosSystem{
    void update(World)(ref World world, float dt){
        world.update!(Position, Velocity)((ref Position p, ref Velocity v){
            writeln(p, " ", v);
        });
    }
}

struct GravitySystem{
    //import breeze.ecs;
    float gravity;
    this(float g){
        gravity = g;
    }
    @disable this();
    void update(World)(ref World world, float dt){
    //    world.updateIndexWorld!(Filter!(Velocity, Physics))((ref cg, index, ref Velocity v, ref Physics p){
    //        v.y -= gravity * dt;
    //    });
      world.updateIndexWorld!(Filter!(Position), (ref cg, index, ref Position pos){
        pos.x = 24;
      });
    }
}

struct UpdatePosSystem{
    void update(World)(ref World world, float dt){
        world.update!(Position, Velocity)((ref Position p, ref Velocity v){
            p.x += v.x * dt;
            p.y += v.y * dt;
        });
    }
}
struct Physics{}

struct RValue(T){
    T value;
    this(T t){
        import std.algorithm.mutation: move;
        value = move(t);
    }
    T release(){
        import std.algorithm.mutation: move;
        return move(value);
    }
    alias release this;

    @disable this(this);
}

struct UniquePtr(T)
{
    private T* ptr;

    @disable this(this);

    UniquePtr release()
    {
        scope(exit) this.ptr = null;
        return UniquePtr(this.ptr);
    }

}

void gcalloc(size_t size){
    import std.experimental.allocator;
    auto arr = theAllocator.makeArray!ubyte(size);
    theAllocator.dispose(arr);
}
void malloc(size_t size){
    import std.experimental.allocator.mallocator;
    import std.experimental.allocator;
    auto arr = Mallocator.instance.makeArray!ubyte(size);
    Mallocator.instance.deallocate(arr);
}
struct DVec3{
    double x,y,z;
}
import std.container: Array;
void test1(const ref Array!DVec3 arr, size_t size, size_t jumpLength){
    import std.random;
    float sum = 0;
    for(size_t i = 0, i2 = 0; i < size; ++i){
        i2 += uniform(0,jumpLength);
        sum += arr[i].x + arr[i].y + arr[i].z;
    }
}
void test2(const ref Array!DVec3 arr, size_t size, size_t jumpLength){
    import std.random;
    float sum = 0;
    for(size_t i = 0, i2 = 0; i < size; ++i){
        i2 += uniform(0,jumpLength);
        sum += arr[i2].x + arr[i2].y + arr[i2].z;
    }
}

string benchCache(size_t size, size_t jumpLength, uint iterations){
    import std.datetime;
    import std.range;
    import std.conv;
    Array!DVec3 a1 = std.range.repeat(DVec3(1,2,3)).take(size * jumpLength);
    auto r = benchmark!(() => test1(a1, size, jumpLength), () => test2(a1, size, jumpLength))(iterations);
    double t1 = to!("seconds", double)((r[0]));
    double t2 = to!("seconds", double)((r[1]));
    return to!string(t1) ~ "," ~ to!string(t2);
}
void main()
{
    import option;
    import std.stdio;
    auto o = some(5);
    writeln(o.expect("Is null"));

    //benchCache(1000000, 3, 100);
    //writeln(o1);
    //   import std.stdio;
    //   import owned, ecs, handlearray;
    //   import std.algorithm.mutation;
    //   import std.experimental.allocator;
    //   import meta;
    //   import std.datetime;
    //   import std.conv;
    //   import std.parallelism;
    //   static import std.container;

    //  auto p = taskPool();
    //  auto t = task!add(1,2);
    //  p.put(t);
    //  writeln(t.yieldForce);
    //    auto u = Position(1,2,3);
    //    int i = 3;
    //    auto t1 = meta.tuple();
    //
    //    alias cg1 = ComponentFamily!(Position, Player, Velocity);
    //    ComponentGroup!cg1 cg;
    //    cg.getHandle!Position();
    //    alias cg2 = ComponentFamily!(Position, Player);
    //    alias cg3 = ComponentFamily!(Position, Velocity);
    //    alias cg4 = ComponentFamily!(Position, Velocity, Player, Physics);
    //    World!(cg1, cg2, cg3, cg4) w;
    //    w.add(Position(1,2,3), Player("1"));
    //    w.add(Position(1,2,3), Player("2"));
    //    w.add(Position(1,2,3), Player("2"), Velocity(1,2,3));
    //    w.add(Position(1,2,3), Velocity(1,2,3));
    //    w.updateIndexWorld!(Filter!(Position), (ref cg, index, ref Position pos){
    //        pos.x = 4;
    //    });
    //
    //    w.updateIndexWorld!(Filter!(Position), (ref cg, index, ref Position pos){
    //        writeln(pos);
    //    });
    //    //
    //    auto sg = systemGroup(w,
    //            GravitySystem(7.81),
    //            UpdatePosSystem(),
    //            PrintPosSystem());
    //    alias a = AliasSeq!(int);
    //    w.add(Position(1,2,3), Velocity(1, 2, 3), Player("Foo"), Physics());
    //    w.add(Position(0,0,0), Velocity(0, 0, 0), Player("Foo1"), Physics());
    //    sg.update(0.16);
    //    sg.update(0.16);
    //  w.update!(Position, Velocity)((ref Position p, ref Velocity v){ writeln(p); writeln(v);});
}
