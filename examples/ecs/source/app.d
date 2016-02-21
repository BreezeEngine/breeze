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

void main()
{
    import breeze.ecs;
    import breeze.meta;
    import std.stdio;
    import std.container;
    import breeze.math.vector;
    import std.exception: enforce;
    auto v = Vector!(float, 3)(1,2,3);
    auto v1 = Vector!(float, 3)(1,2,3);
    auto v3 = v + v1;
    int[5][5] m;
    m[0][0] = 1;
    writeln(m);
    alias cg1 = ComponentGroup!(Array, Position, Velocity);
    cg1 cg;
    cg.add(Position(1,1,1), Velocity(1,1,1));
    cg.add(Position(2,2,2), Velocity(2,2,2));
    auto handle = cg.getHandle!Position(0);
    auto handle2 = cg.getHandle!Position(1);
    cg.remove(0);
    writeln(cg.isValid(handle));
    writeln(cg.isValid(handle2));
    //cg.getHandle!Position();
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
