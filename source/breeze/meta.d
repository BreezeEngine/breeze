module breeze.meta;

import std.meta: allSatisfy;
import std.range;
auto mapToTuple(alias f,T...)(){
    static if(T.length == 0)  {
        return tuple();
    }
    else{
        return tuple(f(T[0]), mapToTuple!(f, T[1..$]).expand);
    }
}
template tupIndexToRange(Indicies...) {
    auto tupIndexToRange(T)(T tup) {
        static if(Indicies.length == 0){
            return tuple();
        }
        else{
            return tuple(tup[ Indicies[0] ][], .tupIndexToRange!(Indicies[1..$])(tup).expand);
        }
    }
}
template mapWithIndex(alias target, alias f, Indicies...){
    auto mapWithIndex(Ts...)(ref Ts ts){
        import std.meta;
        static if(Indicies.length == 0){
            return target();
        }
        else{
            return target(f(ts[Indicies[0]]), .mapWithIndex!(target, f, Indicies[1..$])(ts).expand);
        }
    }
}
template mapTupIndex(alias f, Indicies...){
    auto mapTupIndex(Tup)(ref Tup tup){
        import std.meta;
        static if(Indicies.length == 0){
            return tuple();
        }
        else{
            return tuple(f(tup[Indicies[0]]), .mapTupIndex!(f, Indicies[1..$])(tup).expand);
        }
    }
}

static template same(A...){
    template as(B...)
    if(A.length == 1 && B.length == 1)
    {
        static if(is(typeof(A)) && is(typeof(B))){
            enum as = is(typeof(A) == typeof(B));
        }
        else static if(is(typeof(A)) && !is(typeof(B))){
            enum as = is(typeof(A) == B);
        }
        else static if(!is(typeof(A)) && is(typeof(B))){
            enum as = is(A == typeof(B));
        }
        else{
            enum as = is(A == B);
        }
    }
}

template IndiciesOf(C, T...){
    template IndiciesOfImpl(size_t index,C,T...){
        import std.meta;
        static if(T.length == 0){
            alias IndiciesOfImpl = AliasSeq!();
        }
        else static if(T.length > 0){
            static if(is(C == T[0])){
                alias IndiciesOfImpl = AliasSeq!(index, IndiciesOfImpl!(index + 1, C, T[1..$]));
            }
        else{
                alias IndiciesOfImpl = AliasSeq!(IndiciesOfImpl!(index + 1, C, T[1..$]));
            }
        }
    }
    alias IndiciesOf = IndiciesOfImpl!(0,C,T);
}
template indicies(C...){
    import std.meta;
    template of(T...){
        static if(C.length == 0 || T.length == 0){
            alias of = AliasSeq!();
        }
        else{
            alias of = AliasSeq!(IndiciesOf!(C[0],T), indicies!(C[1..$]).of!T);
        }
    }
}
static template contains(C...){
    import std.meta: anySatisfy;
    template any(T...){
        static if(T.length == 0){
            enum any = false;
        }
        else{
            enum any = containsImpl!((bool a, bool b) => a || b,T);
        }
    }
    template all(T...){
        static if(T.length == 0){
            enum all = false;
        }
        else{
            enum all = containsImpl!((bool a, bool b) => a && b,T);
        }
    }
    template containsImpl(alias pred,T...){
        static if(T.length == 1){
            enum containsImpl = anySatisfy!(same!(T[0]).as,C);
        }
        else{
            enum containsImpl = pred(anySatisfy!(same!(T[0]).as,C), containsImpl!(pred,T[1..$]));
        }
    }
}
struct Tuple(Types...){
    Types values;
    alias values this;
    alias expand = values;
    static if(Types.length > 0){
        this(Types types){
            import std.algorithm.mutation;
            foreach(index, ref t; types){
                values[index] = move(t);
            }
        }
    }
}
auto tuple(Ts...)(Ts ts){
    import std.algorithm.mutation;
    static if(Ts.length == 0){
        return Tuple!Ts(ts);
    }
    else{
        return unpack!(move).into!(Tuple!Ts)(ts);
    }
}
struct TupleRef(Types...){
    import std.meta;
    alias RefTs = staticMap!(RefWrapper, Types);
    RefTs expand;
    static if(Types.length > 0){
        this(ref Types types){
            expand = mapToTuple!(refWrapper, types).expand;
        }
    }
    alias expand this;
}

auto tupleRef(Ts...)(ref Ts ts){
    return TupleRef!(Ts)(ts);
}

template unpack(alias f){
    pragma(inline)
    auto into(alias target, Args...)(auto ref Args args){
        import std.conv;
        import std.algorithm;
        import std.range;
        enum s = `target(`~iota(Args.length).map!(i=>text(`f(args[`,i,`])`)).join(",")~`)`;
        return mixin(s);
    }
}
static template unpackAndFilter(alias f, Indices...){
    pragma(inline)
    auto into(alias target, Args...)(ref Args args){
        import std.conv;
        import std.algorithm;
        import std.range;
        enum s = `target(`~iota(Indices.length).map!(i=>text(`f(args[Indices[`,i,`]])`)).join(",")~`)`;
        pragma(msg,s);
        return mixin(s);
    }
}
static template unpack2(alias f){
    pragma(inline)
    auto into(Args...)(auto ref Args args){
        import std.conv;
        import std.algorithm;
        enum s = iota(Args.length).map!(i=>text(`f(args[`,i,`])`)).join(",");
        return s;
    }
}
static template foldTypes(Types...){
    pragma(inline)
    auto into(alias target, alias t)(){
        import std.conv;
        import std.algorithm;
        enum s = `target(`~iota(Types.length).map!(i=>text(`Types[`,i,`](`,t,`)`)).join(",")~`)`;
        pragma(msg,s);
        return mixin(s);
    }
}
struct RefWrapper(T){
    T* value;

    this(ref T v){
        value = &v;
    }

    ref T access(){
        return *value;
    }
    alias access this;
}

auto refWrapper(T)(ref T t){
    return RefWrapper!(T)(t);
}

ref auto get(R)(ref R r){
    return r.access();
}

struct Zip(alias tuple, Ranges...)
if (Ranges.length && allSatisfy!(isInputRange, Ranges)){
    Ranges ranges;
    this(Ranges ranges){
        this.ranges = ranges;
    }
    bool empty(){
        return unpack!((ref a) => a.empty()).into!(or)(ranges);
    }
    auto ref front(){
        return unpack!(cfront).into!(tuple)(ranges);
    }
    void popFront(){
        foreach(ref range; ranges){
            range.popFront();
        }
    }
}

auto ref cfront(T)(ref T t){
    return t.front();
}

auto zipRef(Ranges...)(Ranges ranges){
    return Zip!(tupleRef, Ranges)(ranges);
}

auto zip(Ranges...)(Ranges ranges){
    import std.typecons: tuple;
    return Zip!(tuple, Ranges)(ranges);
}
R logicalOr(R, Ts...)(Ts ts){
    R result = 0;
    foreach(t; ts){
        result |= t;
    }
    return result;
}
bool or(Ts...)(Ts ts){
    foreach(index, t; ts){
        if(ts[index]){
            return true;
        }
    }
    return false;
}
ref T id(T)(ref T t){
    return t;
}
