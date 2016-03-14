module breeze.collsion.dynamictree;
import std.stdio;
import breeze.math.primitives;

struct DynamicTree{
    import breeze.math.primitives;
}
struct Node{
    union NodeUnion{
        Branch branch;
        Leaf leaf;
    }

    NodeUnion nodeUnion;
    enum Type{LeafType, BranchType}
    Type type;

    this(in Branch b){
        nodeUnion.branch = b;
        type = Type.BranchType;
    }

    this(in Leaf l){
        nodeUnion.leaf = l;
        type = Type.LeafType;
    }

    T* peek(T)()
    if(is(T == Branch) || is(T == Leaf)){
        static if(is(Branch == T)){
            if(type is Type.BranchType){
                return &nodeUnion.branch;
            }
        }
        static if(is(Leaf == T)){
            if(type is Type.LeafType){
                return &nodeUnion.leaf;
            }
        }
        return null;
    }

}


struct Branch{
    int index;
    int left;
    int right;
}
struct Leaf{
    int index;
}
unittest{
}
unittest{
    import std.meta: AliasSeq, staticMap;
    import std.traits: Largest;
    import std.algorithm.comparison: max;
    alias Types = AliasSeq!(int, float, char, double);
    enum size(T) = T.sizeof;
    enum maxSize = max(staticMap!(size, Types));
}
import std.traits: isInstanceOf;
enum isType(T) = isInstanceOf!(Type, T);

struct Type(T){
    alias type = T;
    string toString()
    {
        return "Type!("~T.stringof~")";
    }
}

enum equals(A,B)(Type!A, Type!B){
    return is(A == B);
}

enum isTypeTuple(T) = isInstanceOf!(TypeTuple, T);

struct TypeTuple(Types...){
    import std.meta: allSatisfy;
    static assert(allSatisfy!(isType, Types), "Variadic parameters need to be of type 'Type!'");
    Types expand;
    alias expand this;
    string toString()
    {
        import std.range;
        string[] s;
        foreach(t; expand){
            s~= t.toString();
        }
        return "TypeTuple!(" ~ s.join(", ") ~")";
    }
}

enum typeTuple(Types...)(Types){
    return TypeTuple!Types();
}

enum tupleFromTypes(Ts...)(){
    import std.meta: staticMap;
    return TypeTuple!(staticMap!(Type, Ts))();
}

enum filter(alias f, Tup)(Tup){
    static assert(isTypeTuple!(Tup), tup.stringof~" is not a TypeTuple.");
    enum tup = Tup();
    static if(tup.length == 0){
        return typeTuple();
    }
    else static if(f(tup[0])){
        return typeTuple(tup[0], filter!(f)(typeTuple(tup[1..$])).expand);
    }
    else{
        return filter!(f)(typeTuple(tup[1..$]));
    }
}

enum map(alias f, Tup)(Tup){
    static assert(isTypeTuple!(Tup), tup.stringof~" is not a TypeTuple.");
    enum tup = Tup();
    static if(tup.length == 0){
        return typeTuple!();
    }
    else{
        return typeTuple(f(tup[0]), map!(f)(typeTuple(tup[1..$])).expand);
    }
}

enum indexOf(T,Tup)(T, Tup){
    static assert(isTypeTuple!(Tup), tup.stringof~" is not a TypeTuple.");
    static assert(isType!(T), T.stringof~" is not a Type.");
    enum t = T();
    enum tup = Tup();
    foreach(index, type; tup.expand){
        if(type.equals(t)){
            return index;
        }
    }
    return -1;
}

enum sort(alias f,Tup)(Tup){
    enum tup = Tup();
    static if(tup.length == 0){
        return typeTuple();
    }
    else static if(tup.length == 1){
        return typeTuple(tup[0]);
    }
    else{
        enum middle= tup[0];
        enum t = partition!(t => f(t, middle))(typeTuple(tup[1..$]));
        enum left = t[0];
        enum right = t[1];
        return typeTuple(left.expand, middle, right.expand);
    }
}

enum partition(alias f, Tup)(Tup){
    enum tup = Tup();
    return partitionImpl!(f)(tup, typeTuple(), typeTuple());
}

enum partitionImpl(alias f, Tup, TupLeft, TupRight)(Tup, TupLeft, TupRight){
    import std.typecons: tuple;
    enum tup = Tup();
    enum l = TupLeft();
    enum r = TupRight();

    static if(tup.length == 0){
        return tuple(l, r);
    }
    else{
        static if(f(tup[0])){
            return partitionImpl!(f)(typeTuple(tup[1..$]), typeTuple(tup[0], l.expand), typeTuple(r.expand));
        }
        else{
            return partitionImpl!(f)(typeTuple(tup[1..$]), typeTuple(l.expand), typeTuple(tup[0], r.expand));
        }

    }
}


//struct Command1{
//    int i;
//    int j;
//}
//struct Command2{
//    int i;
//}
//
////unittest{
//    import std.meta;
//    import std.container: Array, DList;
//    import std.algorithm.mutation;
//    import std.bitmanip;
//    Array!ubyte byteArray;
//    alias Commands = AliasSeq!(Command1, Command2);
//
//    auto bytes = cast(ubyte[Command1.sizeof])Command1(1,2);
//
//    uint index = IndexOf!(Command1, Commands);
//    auto bytesIndex = nativeToLittleEndian(index);
//    byteArray.insertBack(bytesIndex[]);
//    writeln(byteArray[]);
//    byteArray.insertBack(bytes[]);
//
//    ubyte[4] b;
//    byteArray[0..4].copy(b[]);
//    writeln(byteArray[]);
//    writeln(IndexOf!(Command1, Commands));
//    writeln(b);
//    uint i = (cast(int[])b)[0];
//
//    foreach(ind, type; Commands){
//        if(ind == i){
//            writeln(type.stringof);
//            ubyte[Command1.sizeof] commandByte;
//            byteArray[4 .. 4 + Command1.sizeof].copy(commandByte[]);
//            writeln(commandByte[]);
//            writeln(cast(Command1)commandByte);
//        }
//    }
//}


