struct Some(T){
    T value;
}
struct None{}

struct Option(T){
    bool isNone(){
        return !hasValue;
    }
    bool isSome(){
        return hasValue;
    }
    ref T get(){
        import std.exception: enforce;
        enforce(isSome, "");
        return value;
    }
    string toString(){
        import std.conv;
        import std.format;
        if(isSome){
            return "Some!(%s)( %s )".format(T.stringof, value.to!string);
        }
        return "None!(%s)()".format(T.stringof);
    }
private:
    this(ref T value){
        this.value = value;
        hasValue = true;
    }
    this(T value){
        import std.algorithm: move;
        this.value = move(value);
        hasValue = true;
    }
    bool hasValue = false;
    T value;
}

Option!T some(T)(ref T value){
    return Option!T(value);
}
Option!T some(T)(T value){
    import std.algorithm: move;
    return Option!T(move(value));
}
Option!T none(T)(){
    return Option!T();
}

T unwrapOr(T)(auto ref Option!T option, T defaultValue){
    if(option.isSome){
        return option.get;
    }
    else{
        return defaultValue;
    }
}

T expect(T)(auto ref Option!T option, string message){
    if(option.isSome){
        return option.get;
    }
    assert(false, message);
}



unittest{
  struct Foo{
    int someInteger;
  }
  Foo f;
  
}

