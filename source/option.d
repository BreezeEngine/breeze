import std.variant;
//struct Some(T){
//    T value;
//}
//struct None{}
//
//struct Option(T){
//    alias OptionAdt(T) = Algebraic!(Some!T, None);
//    OptionAdt!T value = OptionAdt!T(None());
//    bool isNone(){
//        return value.peek!None !is null;
//    }
//    bool isSome(){
//        return value.peek!(Some!T) !is null;
//    }
//    bool isNotInitialized(){
//        return isSome == isNone;
//    }
//    ref T expect(string message){
//        if(isNone ){
//            throw new Error(message);
//        }
//        return value.peek!(Some!T).value;
//    }
//    T unwrap(){
//        import std.algorithm: move;
//        if(isNone){
//            throw new Error("Calling 'unwrap' on None is not allowed");
//        }
//        return move(value.peek!(Some!T).value);
//    }
//    T unwrapOr(T defaultValue){
//        import std.algorithm: move;
//        if(isNone){
//            return move(defaultValue);
//        }
//        else{
//          return unwrap();
//        }
//    }
//private:
//    this(ref T value){
//        this.value = OptionAdt!T(Some!T(value));
//    }
//    this(T value){
//        import std.algorithm: move;
//        this.value = OptionAdt!T(Some!T(move(value)));
//    }
//    this(None){
//        value = OptionAdt!T(None());
//    }
//    @disable this();
//}
//
//Option!T some(T)(ref T value){
//    return Option!T(value);
//}
//Option!T some(T)(T value){
//    import std.algorithm: move;
//    return Option!T(move(value));
//}
//Option!T none(T)(){
//    return Option!T(None());
//}

alias Option(T) = Algebraic!(Some!T, None);

bool isNone(T)(auto ref Option!T o){
    return true;
}


