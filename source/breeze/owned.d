module breeze.owned;
import std.stdio;

template AsPtr(T){
    static if (is(T:Object))
        alias AsPTr = T;
    else
        alias AsPTr = T*;
}
struct OwnedRef(T){
    import std.typecons: Proxy;
    OwnedRefImpl!T* w;
    private this(OwnedRefImpl!T* w){
        this.w = w;
    }
    bool expired(){
        return w is null || w.expired;
    }
    mixin Proxy!w;
}
struct OwnedRefImpl(T){
    import std.typecons: Proxy;
    static if (is(T:Object))
        alias RefT = T;
    else
        alias RefT = T*;
    this(T* t){
        ptr = t;
    }
    bool expired(){
        return ptr is null;
    }
    auto ref get(){
        if (expired()){
            throw new Error("Access of expired OwnedRef.");
        }
        return *ptr;
    }
    mixin Proxy!get;
    private T* ptr;
}
struct Owned(T){
    import std.experimental.allocator;
    import std.typecons: Proxy;
    static if (is(T:Object)){
        alias RefT = T;
        @safe ref T get(){
            return ptr;
        }
    }
    else{
        @safe ref T get(){
            return *ptr;
        }
        alias RefT = T*;
    }
    this(Args...)(auto ref Args args){
        import std.experimental.allocator.mallocator;
        alloc = allocatorObject(Mallocator.instance);
        ptr = alloc.make!T(args);
        wref = new OwnedRefImpl!T(ptr);
    }
    OwnedRef!(T) getRef()
    {
        if(expired())
            throw new Error("Owned is expired.");
        return OwnedRef!T(wref);
    }
    bool expired(){
        return (wref is null) || (ptr is null);
    }
    void free(){
        if(wref !is null)
            wref.ptr = null;
        if(alloc !is null)
            alloc.dispose(ptr);
    }
    ~this(){
        free();
    }
    Owned release(){
        import std.algorithm.mutation: move;
        return move(this);
    }
    @disable this(this);
    OwnedRefImpl!T* wref;
private:
    IAllocator alloc;
    RefT ptr;
}
