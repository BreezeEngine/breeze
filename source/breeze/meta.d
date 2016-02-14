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
static template unpack(alias f){
    pragma(inline)
    auto into(alias target, Args...)(auto ref Args args){
        import std.conv;
        import std.algorithm;
        import std.range;
        enum s = `target(`~iota(Args.length).map!(i=>text(`f(args[`,i,`])`)).join(",")~`)`;
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
struct TupleRef(Ts...){
    import std.meta;
    alias RefTs = staticMap!(RefWrapper, Ts);
    RefTs expand;
    this(ref Ts ts){
        expand = mapToTuple!(refWrapper, ts).expand;
    }
    ref auto into(alias f)(){
        return unpack!get.into!f(expand);
    }
    alias expand this;
}

auto tupleRef(Ts...)(ref Ts ts){
    return TupleRef!(Ts)(ts);
}

ref auto get(R)(ref R r){
    return r.access();
}
struct MyZip(Ranges...)
if (Ranges.length && allSatisfy!(isInputRange, Ranges)){
    Ranges ranges;
    this(Ranges ranges){
        this.ranges = ranges;
    }
    bool empty(){
        return unpack!((ref a) => a.empty()).into!(or)(ranges);
    }
    auto ref front(){
        return unpack!(cfront).into!(tupleRef)(ranges);
    }
    void popFront(){
        foreach(ref range; ranges){
            range.popFront();
        }
    }
}

ref auto cfront(T)(ref T t){
    return t.front();
}

auto myZip(Ranges...)(Ranges ranges){
    return MyZip!Ranges(ranges);
}
bool or(Ts...)(Ts ts){
    foreach(index, t; ts){
        if(ts[index]){
            return true;
        }
    }
    return false;
}
