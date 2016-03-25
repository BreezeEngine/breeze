module breeze.util.trait;

struct VDispatch(Types...){
    void* vptr;
    char typeId;

    void print(){
        foreach(index, type; Types){
            if(index == typeId){
                (cast(type*)vptr).print();
            }
        }
    }

    int getNumber(){
        foreach(index, type; Types){
            if(index == typeId){
                return (cast(type*)vptr).getNumber();
            }
        }
        throw new Error("Unknown Type");
    }

    this(T)(T* ptr){
        import std.meta: staticIndexOf;
        vptr = cast(void*)ptr;
        typeId = staticIndexOf!(T, Types);
    }
}


struct Foo{
    int number;
    void print(){
        import std.stdio;
        writeln("Foo: ", number);
    }
    int getNumber(){
        return number;
    }
}

struct Bar{
    int number;
    void print(){
        import std.stdio;
        writeln("Bar: ", number);
    }
    int getNumber(){
        return number;
    }
}
enum bool hasInterface(T, I)(){
    import std.meta;
    foreach(name; __traits(allMembers, I)){
        alias func = typeof(__traits(getMember, I, name));
        enum hasName = staticIndexOf!(name,__traits(allMembers, T)) !is -1;
        static assert(hasName, " '"~T.stringof ~ "' does not implement a function with the name '"~ name~ "'. ");

        alias structFunc = typeof(__traits(getMember, T, name));
        static assert(is(func == structFunc), "Types differ for function '" ~name~ "', expected '" ~ func.stringof ~
                                              "' but found '" ~ structFunc.stringof~"'");

        return true;
    }
}
interface IPrint{
    void print();
}
struct No{
}

struct Test1{
    void print(){
        import std.stdio;
        writeln("Test1");
    }
}

struct Test2{
    void print(){
        import std.stdio;
        writeln("Test1");
    }
}

struct Test3(T){
    static assert(hasInterface!(Test3, IPrint));
    void print(){
    }
}
//void print(T)(T t)
//if(hasInterface!(T, IPrint)){
//    t.print();
//}

struct Trait(I, T){
}

struct Trait(I: IPrint, T: No){
    static void print(ref T no){
        import std.stdio;
        writeln("No trait");
    }
}

unittest{
    import std.traits;
    import std.stdio;

    Test1 t1;
    Test2 t2;
    No no;

//    print(t1);
//    print(t2);
    //no.print();

    //    import std.stdio;
    //    alias VFooBar = VDispatch!(Foo, Bar);
    //    auto t = VFooBar(new Foo(42));
    //    auto t1 = VFooBar(new Bar(24));
    //    t.print();
    //    t1.print();
    //    writeln(t.getNumber());
    //    writeln(t1.getNumber());
    //
    //    writeln(char.sizeof);
}

