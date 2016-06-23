module breeze.util.algebraic;
import std.stdio;
struct Algebraic(Types...)
if(Types.length < char.max - 1){
    import std.meta: IndexOf;

    @disable this();
    this(T)(T t){
        enum index = IndexOf!(T, Types);
        static assert(index >=0, "Type: '"~T.stringof~"'" ~ " is not inside " ~ Types.stringof);
        type = index;
        types[index] = t;
    }

    void opAssign(T)(T t){
        enum index = IndexOf!(T, Types);
        static assert(index >=0, "Type: '"~T.stringof~"'" ~ " is not inside " ~ Types.stringof);
        type = index;
        types[index] = t;
    }

    void opAssign()(auto ref Algebraic!Types other){
        types = other.types;
        type = other.type;
    }

    inout(T*) peek(T)() inout{
        enum index = IndexOf!(T, Types);
        static if(index is -1){
            return null;
        }
        else{
            if(type is index){
                return &types[index];
            }
            return null;
        }
    }

    auto match(Matches...)(){
        import std.traits;
        import std.meta;
        alias MatchesParams = staticMap!(Parameters, Matches);
        foreach(matchParam; MatchesParams){
            static assert(
                IndexOf!(
                    matchParam, Types) !is -1,
                    matchParam.stringof ~ " is not a type of " ~ typeof(this).stringof );
        }
        static assert(NoDuplicates!MatchesParams.length is MatchesParams.length, "Contains duplicates");
        static assert(MatchesParams.length is Types.length, "Not enough matches");
        alias ReturnTypes = staticMap!(ReturnType, Matches);
        static assert(NoDuplicates!ReturnTypes.length is 1, "All matches need to return the same type");
        foreach(match; Matches){
            alias param = Parameters!match[0];
            enum index = IndexOf!(param, Types);
            if(index is type){
                return match(*peek!param);
            }
        }
        assert(0);
    }

    char type = char.max;
    union{
        Types types;
    }
}
unittest{
    struct Foo{
        int* i;
    }
    alias Test = Algebraic!(uint, float);
    enum uint i = 5;
    enum float f = 5.0f;
    enum Test a = i;
    auto b = Test(f);
    auto ii = b.match!(
        (uint i) => 10,
        (float f) => 1,
    );
}
