module breeze.fn;
import std.stdio;

struct Delegate(R, Params...){
    import std.experimental.allocator.mallocator;
    R delegate(Params) del;

    ~this(){
        Mallocator.instance.deallocate(del.ptr);
    }
}

template Function(_R, _Params...){
    import std.meta;
    interface Function{
        alias R = _R;
        static if(is(_Params == AliasSeq!(void))){
            alias Params = AliasSeq!();
        }
        else{
            alias Params = _Params;
        }
        R call(Params);
    }
}
import std.experimental.allocator.mallocator;
class Closure(Function, F, CapturedVars...): Function!(Function.R, Function.Params){
    import std.traits;
    import std.meta;
    import std.typecons;
    CapturedVars vars;

    F f;

    this(F f, CapturedVars _vars){
        import std.algorithm.mutation;
        this.f = f;
        //vars = _vars;
        foreach(index, ref var; _vars){
            vars[index] = _vars[index].move;
        }
    }
//    static if(vars.length > 0){
//        @disable this();
//        this(CapturedVars _vars){
//            vars = _vars;
//        }
//    }
//    else{
//        this(){
//        }
//    }


    //FnType.R opCall(FnType.Params params){
    //    return f(params, vars);
    //}
    Function.R call(Function.Params params){
        return f(params, vars);
    }

//    static if(!is(FnType.R == void)){
//        auto toDelegate(FnType.Params params){
//            auto result = opCall(params);
//            this.destroy();
//            return result;
//        }
//    }
}
auto fnboxed(Function, F, CapturedVars...)(F f, CapturedVars vars){
    import breeze.memory;
    import std.traits;
    import std.meta;
    pragma(msg, "FunctionTypeN ", F);
    alias CapturedVars1 = Parameters!F[Function.Params.length .. $];
    //static assert(
    //    is(CapturedVars1 == CapturedVars),
    //    "Mismatched function type params"
    //);
    pragma(msg, "Closure ", Closure!(Function, F, CapturedVars));
    import std.algorithm.mutation;
    auto c = box!(Closure!(Function, F, CapturedVars))(f, vars.move);
    //auto c = box!(Closure!(Function, F, CapturedVars))(f, vars);
    return c;
}
//template isFn(FnType, alias f){
//    import std.traits;
//    static if(is(f)){
//        alias F = f;
//    }
//    else{
//        alias F = typeof(f);
//    }
//    enum isFn = __traits(isSame, TemplateOf!(F), Fn) && is(F.FnType == FnType);
//}

unittest{
//    auto printCapturedVars = Fn!(FnType!void, (int capturedA, int capturedB){
//        writeln(capturedA, " ", capturedB);
//    })(10, 20);
//    printCapturedVars();

//    auto test = box!(Closure!(FnType!(void, void), (int capturedVar){
//        writeln(capturedVar);
//    }))(5);
//    test.call();
//    testFunc!printCapturedVars();
//
//    auto test1 = box3!(Closure!(FnType!(void, void), (){
//        writeln("empty");
//    }))();
//    import std.algorithm.mutation;
//    auto test3 = Box!(Function!(void))(test1);
//    writeln(test3.value);
//    writeln("asd");
//    import std.experimental.allocator;
//    auto val = Mallocator.instance.make!(Closure!(FnType!(void, void), (){
//        writeln("empty");
//    }))();
//    auto test2 = Box!(Function!(void))(val);
//    test2.call();
//    test1.call();
//    auto add = box!(Closure!(FnType!(int, int), (int i, int capturedVar){
//        return i + capturedVar;
//    }))(42);
//    writeln(add.call(1));
//
//    alias test = int delegate(int);
//
//    test t = &add.toDelegate;
//
//    writeln(add(1)); //prints 43
//    writeln(t(1)); //prints 43
}
