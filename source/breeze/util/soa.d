module breeze.util.soa;
import std.stdio;
struct SOA(T){
    import std.experimental.allocator;
    import std.experimental.allocator.mallocator;

    import std.meta: staticMap;
    import std.typecons: Tuple;
    import std.traits: FieldNameTuple;

    alias toArray(T) = T[];
    alias toType(string s) = typeof(__traits(getMember, T, s));

    alias MemberNames = FieldNameTuple!T;
    alias Types = staticMap!(toType, MemberNames);
    alias ArrayTypes = staticMap!(toArray, Types);

    this(size_t _size, IAllocator _alloc = allocatorObject(Mallocator.instance)){
        alloc = _alloc;
        size = _size;
        _length = size;
        allocate(size);
    }

    ref auto opDispatch(string name)() inout{
        import std.meta: staticIndexOf;
        alias index = staticIndexOf!(name, MemberNames);
        static assert(index >= 0);
        return containers[index];
    }

    void insertBack(Types types){
        if(length == size) grow;
        foreach(index, ref container; containers){
            container[length] = types[index];
        }
        length = length + 1;
    }

    void insertBack(T t){
        if(length == size) grow;
        foreach(index, _; Types){
            containers[index][length] = __traits(getMember, t, MemberNames[index]);
        }
        length = length + 1;
    }

    size_t length() const @property{
        return _length;
    }

    ~this(){
        if(alloc is null) return;
        foreach(ref container; containers){
            alloc.dispose(container);
        }
    }

    size_t _length = 0;
private:
    void length(size_t len)@property{
        _length = len;
    }

    Tuple!ArrayTypes containers;
    IAllocator alloc;

    size_t size = 0;
    short growFactor = 2;

    void allocate(size_t size){
        if(alloc is null){
            alloc = allocatorObject(Mallocator.instance);
        }
        foreach(index, ref container; containers){
            container = alloc.makeArray!(Types[index])(size);
        }
    }

    void grow(){
        import std.algorithm: max;
        size_t newSize = max(1,size * growFactor);
        size_t expandSize = newSize - size;

        if(size is 0){
            allocate(newSize);
        }
        else{
            foreach(ref container; containers){
                alloc.expandArray(container, expandSize);
            }
        }
        size = newSize;
    }
}

struct SOA2(T, alias Container){
    import std.experimental.allocator;
    import std.experimental.allocator.mallocator;

    import std.meta: staticMap;
    import std.typecons: Tuple;
    import std.traits: FieldNameTuple;

    alias toType(string s) = typeof(__traits(getMember, T, s));

    alias MemberNames = FieldNameTuple!T;
    alias Types = staticMap!(toType, MemberNames);
    alias ArrayTypes = staticMap!(Container, Types);

    this(size_t _size, IAllocator _alloc = allocatorObject(Mallocator.instance)){
        alloc = _alloc;
        length = _size;
        foreach(ref container; containers){
            //container.length(_size);
        }
    }

    ref auto opDispatch(string name)() inout{
        import std.meta: staticIndexOf;
        alias index = staticIndexOf!(name, MemberNames);
        static assert(index >= 0);
        return containers[index];
    }

    void insertBack(Types types){
        foreach(index, ref container; containers){
            container.insert(types[index]);
        }
        length = length + 1;
    }

    void insertBack(T t){
        foreach(index, _; Types){
            containers[index].insert(__traits(getMember, t, MemberNames[index]));
        }
        length = length + 1;
    }

    size_t length() const @property{
        return _length;
    }

private:
    void length(size_t len)@property{
        _length = len;
    }

    ArrayTypes containers;
    IAllocator alloc;

    size_t _length = 0;
}
unittest{
    struct Vec2{
        float x;
        float y;
    }
    import containers.dynamicarray;
    static import breeze.handlearray;
    import std.container;
//    writeln("D: ", DynamicArray!(int).sizeof);
//    writeln("D1: ", Array!(int).sizeof);
//    writeln("D2: ", breeze.handlearray.Array!(int).sizeof);
//    writeln("D3: ",(int[]).sizeof);
//    auto s1 = SOA2!(Vec2, Array)();
}
