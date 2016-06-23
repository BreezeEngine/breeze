module breeze.memory;
import std.stdio;

import std.experimental.allocator.mallocator;

struct Box(T, Allocator = Mallocator){
    import std.experimental.allocator;
    import std.typecons: Proxy;
    alias allocator = Allocator.instance;

    enum isObject = is(T:Object) || is(T == interface);

    static if(isObject){
        alias RefT = T;
    }
    else{
        alias RefT = T*;
    }

    @disable
    void opAssign(T val);

    void opAssign(Box!T b){
        allocator.dispose(value);
        value = b.value;
    }

    @disable this(this);
    ~this(){
        allocator.dispose(value);
    }

    this(U)(U val)
    if(is(U == class) && is(T:U)){
       value = val;
    }

    this(U)(Box!U other)
    if(is(U:T)){
        value = other.value;
        other.value = null;
    }

    this(Args...)(auto ref Args args) {
        value = allocator.make!T(args);
    }

//    Box!(T) dup(){
//        if(value !is null){
//            static if (isObject){
//                return Box!(T, Allocator)(value);
//            }
//            else{
//                return Box!(T, Allocator)(*value);
//            }
//        }
//        else{
//            return Box!(T, Allocator).init;
//        }
//    }

    T opUnary(string op)()
    if(op is "*"){
        static if(isObject){
            return value;
        }
        else{
            return *value;
        }
    }

    string toString(){
        import std.conv;
        if(value is null){
            return "Box( null )";
        }
        else{
            static if(isObject){
                return typeof(this).stringof ~ "( " ~ value.to!string ~ " )";
            }
            else{
                return typeof(this).stringof ~ "( " ~ (*value).to!string ~ " )";
            }
        }
    }
    mixin Proxy!value;
    RefT value = null;
}

auto box3(T, Allocator = Mallocator, Args...)(){
    import std.experimental.allocator;
    T val = Allocator.instance.make!T();
    return Box!(T, Allocator)(val);
}
auto box(T, Allocator = Mallocator, Args...)(auto ref T arg){
    return Box!(T, Allocator)(arg);
}

string mixinMove(args...)(){
    import breeze.util.array;
    import std.range;
    import std.conv;
    string[] result;
    foreach(index, _; args){
        result~= ("args[" ~ index.to!string ~ "].move()");
    }
    return result[].join(",");
}
auto box(T, Allocator = Mallocator, Args...)(auto ref Args args){
    import std.algorithm.mutation;
    writeln(mixinMove!args);
    //return Box!(T, Allocator)(args);
    return mixin("Box!(T, Allocator)(" ~ mixinMove!Args ~ ")");
}
unittest{
    import std.stdio;
    import std.experimental.allocator;
    import std.algorithm.mutation;

}

