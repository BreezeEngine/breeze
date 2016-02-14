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
struct ComponentHandle(IndexType, HashType){
    IndexType index;
    HashType hash;
    this(IndexType index, HashType hash){
        this.index = index;
        this.hash = hash;
    }
}
struct EntityManager(IndexType, HashType){
    import std.container: Array, DList;
    Array!HashType hashes;
    DList!IndexType freeIndices;

    bool isValid(EntityHandle)(EntityHandle handle){
        return hashes[handle.index] is handle.hash;
    }
    void invalidate(EntityHandle)(EntityHandle handle){
        hashes[handle.index] += 1;
        freeIndices.insertBack(handle.index);
    }
    auto create(Components...)(){
        alias EntityHandle = ComponentHandle!(IndexType, HashType);
        if(!freeIndices.empty){
            auto index = freeIndices.front();
            freeIndices.removeFront();
            return EntityHandle(index, hashes[index]);
        }
        else{
            enum HashType zeroHash = 0;
            hashes.insertBack(zeroHash);
            IndexType index = cast(IndexType) hashes.length - 1;
            return EntityHandle(index, hashes[index]);
        }
    }
}
struct ComponentGroup(alias Container, Components...)
if(!hasDuplicates!(Components)){
    import std.meta: staticMap,Filter;
    import std.range;
    import option;
    alias IndexType = uint;
    alias HashType = short;
    static alias Components1 = Components;
    alias ComponentsContainer = staticMap!(Container, Components);
    EntityManager!(IndexType, HashType) entityManager;

    IndexType[IndexType] entityIndexMap;
    IndexType[IndexType] indexEntityMap;

    size_t length = 0;
    enum hasComponents(T...) = contains!Components.all!T;

    auto getHandle(C...)(IndexType index){
        auto handle = entityManager.create!C();
        entityIndexMap[handle.index] = index;
        indexEntityMap[index] = handle.index;
        return handle;
    }
    auto get(C...)(ComponentHandle!(IndexType, HashType) handle){
        if(!entityManager.isValid(handle)){
            return none!(Tuple!(staticMap!(RefWrapper,C)))();
        }
        auto elementIndex = entityIndexMap[handle.index];
        alias indices = indicies!C.of!Components;
        auto t = unpackAndFilter!(id, indices).into!(tupleRef)(componentContainer.expand);
        return some(unpack!((ref c){ return refWrapper(c[elementIndex]);}).into!(tuple)(t.expand));

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
    void swap(IndexType first, IndexType second){
        import std.algorithm.mutation;
        foreach(ref container; componentContainer){
          swap(container[first], container[second]);
        }
        if(first in indexEntityMap && second in indexEntityMap){
            IndexType firstEntity = indexEntityMap[first];
            IndexType secondEntity = indexEntityMap[second];

            entityIndexMap[firstEntity] = second;
            entityIndexMap[secondEntity] = first;
        }
    }

    void remove(size_t index){
        //foreach(ref container; componentContainer){
        //    container.remove(index);
        //}
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
