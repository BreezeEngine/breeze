module breeze.util.result;

struct Ok(T){
    T value;
}

struct Err(E){
    E value;
}

struct Result(T, E){
    import breeze.util.algebraic;
    alias ValueType = T;
    alias ErrorType = E;
    alias ResultT = Algebraic!(Ok!T, Err!E);
    ResultT value;
    alias value this;
    this(R)(R val){
        value = val;
    }
    static Result!(T, E) ok(T value){
        return Result!(T, E)(Ok!T(value));
    }
    static Result!(T, E) err(E error){
        return Result!(T, E)(Err!E(error));
    }
    auto match(Matches...)(){
        return value.match!(Matches);
    }
}


unittest{
    import breeze.util.algebraic;
    import std.stdio;
    alias SomeRes = Result!(int, string);
    auto a = SomeRes.ok(5);
    auto b = SomeRes.err("Test");
//    a.match!(
//        (Ok!int i) => writeln(i.value),
//        (Err!string msg) => writeln(msg)
//    );
}
