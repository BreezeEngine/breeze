module breeze.util.algebraic;
import std.stdio;
struct Algebraic(Types...)
if(Types.length < char.max - 1){
    import std.meta: IndexOf;

    this(T)(in T t){
        enum index = IndexOf!(T, Types);
        static assert(index >=0, "Type: '"~T.stringof~"'" ~ " is not inside " ~ Types.stringof);
        type = index;
        types[index] = t;
    }

    void opAssign(T)(in T t){
        enum index = IndexOf!(T, Types);
        static assert(index >=0, "Type: '"~T.stringof~"'" ~ " is not inside " ~ Types.stringof);
        type = index;
        types[index] = t;
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
private:
    char type = char.max;
    union{
        Types types;
    }
}
unittest{
    alias Test = Algebraic!(int, float);
    Test a = 5;
    //writeln(*a.peek!int);
}
