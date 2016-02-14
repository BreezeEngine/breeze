module breeze.ecs;

import breeze.meta;

import std.typetuple: allSatisfy;
import std.range;

struct Filter(C...){
    alias all = C;
}
struct SystemGroup(World, Systems...){
    import std.typecons: Tuple, tuple;
    World* world;
    Tuple!Systems systems;

    this(ref World w, Systems s){
        systems = tuple(s);
        world = &w;
    }
    void update(float dt){
        foreach(ref system; systems){
            system.update(*world, dt);
        }
    }
}
struct ComponentFamily(C...){
    alias Components = C;
}
auto systemGroup(World, Systems...)(ref World world, Systems systems){
    return SystemGroup!(World, Systems)(world,systems);
}

static template hasComponents(T...){
    template of(EG){
        enum of = contains!(EG.Components).all!T;
    }
}
template hasDuplicates(Ts...){
    import std.meta: Filter;
    static if(Ts.length == 0){
        enum hasDuplicates = false;
    }
    static if(Ts.length > 0){
        import breeze.meta;
        alias dup = Filter!(same!(Ts[0]).as, Ts[1..$]);
        static if(dup.length > 0){
            enum hasDuplicates = true;
        }
    else{
            enum hasDuplicates = hasDuplicates!(Ts[1..$]);
        }
    }
}
struct GroupHandle(Components...){
    import breeze.handlearray;
    import std.meta;
    alias Handles = staticMap!(Handle, Components);
    breeze.meta.Tuple!(Handles) handles;
    this(Handles handles){
        this.handles = handles;
    }
    auto get(Component)(){
        return handles[staticIndexOf!(Component, Components)];
    }

    bool expired(){
        return unpack!((ref h) => h.expired).into!(or)(handles.expand);
    }
}
struct ComponentGroup(alias Container, Components...)
if(!hasDuplicates!(Components))
{
    import std.meta: staticMap,Filter;
    import std.typecons;
    import std.range;
    static alias Components1 = Components;
    alias ComponentsContainer = staticMap!(Container, Components);

    size_t length = 0;
    enum hasComponents(T...) = contains!Components.all!T;

    auto getHandle(C...)(size_t index){
        alias indices = indicies!C.of!Components;
        auto t = mapTupIndex!((ref a){
            return a.getHandle(index);
        },indices)(componentContainer);
        return GroupHandle!C(t.expand);
    }
    template groupView(C...){
        alias groupView = indicies!(staticMap!(Container,C)).of!ComponentsContainer;
    }
    void add(Components components){
        import std.meta: staticIndexOf;
        foreach(index, comp; components){
            componentContainer[index].insertBack(comp);
        }
        length += 1;
    }

    auto ref getRange(C...)(){
        alias indices = indicies!C.of!Components;
        auto r =  tupIndexToRange!(indices)(componentContainer);
        return myZip(r.expand);
    }

    void remove(size_t index){
        foreach(ref container; componentContainer){
            container.remove(index);
        }
    }

    breeze.meta.Tuple!ComponentsContainer componentContainer;
}
static template updateIndex(Filter, alias f){
    void updateIndex(CG)(ref CG cg){
        foreach(index, ref t; cg.getRange!(Filter.all)().enumerate(0)){
            f(cg, index, t.expand);
        }
    }
}
struct World(EntityViews...)
if(!hasDuplicates!(EntityViews))
{
    import std.typecons: Tuple;
    import std.meta: staticMap;
    import breeze.handlearray;
    template CompConstructor(CF){
        alias CompConstructor = ComponentGroup!(HandleArray, CF.Components);
    }
    alias ComponentGroups = staticMap!(CompConstructor, EntityViews);
    breeze.meta.Tuple!ComponentGroups entityViews;

    alias Ev = EntityViews;
    auto getRange(C...)(){
        import std.meta: Filter;
        import std.range;
        alias filteredComponents = Filter!(hasComponents!C.of, EntityViews);
        alias ind = indicies!filteredComponents.of!EntityViews;
        auto nr = mapTupIndex!(e => e.getRange!C(), ind)(entityViews);
        return chain(nr.expand);
    }

    void add(Components...)(Components components){
        import std.container: Array;
        import std.meta: staticIndexOf;
        import breeze.handlearray;
        alias cg = ComponentFamily!Components;
        alias index = staticIndexOf!(cg, EntityViews);
        static assert(index <= Components.length, "No ComponentFamily of type " ~ Components.stringof ~ " exists.");
        entityViews[index].add(components);
    }
    template update(C...){
        void update(F)(F f){
            static if(C.length == 1){
                foreach(t; getRange!C){
                    f(t);
                }
            }
            else{
                foreach(t; getRange!C){
                    f(t.expand);
                }
            }
        }
    }
}

static template updateIndexWorld(CFilter, alias f){
    void updateIndexWorld(World)(ref World world){
        import std.meta: Filter;
        import std.range;
        alias filteredComponents = Filter!(hasComponents!(CFilter.all).of, world.Ev);
        alias ind = indicies!filteredComponents.of!(world.Ev);
        //        //    auto nr = mapTupIndex!(e => e.getRange!C(), ind)(entityViews);
        foreach(index; ind){
            world.entityViews[ind[index]].updateIndex!(CFilter, f);
        }

    }
}
