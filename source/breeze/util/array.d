module breeze.util.array;

import std.stdio;
struct ArrayRange(T){
    T* array;
    size_t current;
    this(T* t){
        array = t;
        current = 0;
    }

    bool empty(){
        return current >= array.length;
    }

    void popFront(){
        current += 1;
    }

    ref auto front(){
        return array.access(current);
    }

    ref auto back(){
        return array.access(array.length - 1);
    }

    ref auto opIndex(size_t index){
        return array.access(index);
    }
}

import std.experimental.allocator.mallocator;
struct Array(T, Allocator = Mallocator){
    import std.experimental.allocator;
    enum isObject = is(T:Object);
    static if(isObject){
        alias RefT = T;
    }
    else{
        alias RefT = T*;
    }
    alias allocator = Allocator.instance;
    T[] data;

    size_t length = 0;

    auto range(){
        return ArrayRange!(Array!(T, Allocator))(&this);
    }
    int growFactor = 2;

    this(size_t size) {
        data = cast(T[])allocator.allocate(T.sizeof * size);
        length = size;
    }
    @disable this(this);
    ~this(){
        allocator.deallocate(data);
    }

    auto opDispatch(string s)(){
        return mixin("value." ~ s);
    }

    auto ptr(){
      return data.ptr;
    }

    //auto dup(){
    //    auto arr = Array!(T, Allocator).init;
    //    arr.data = data.dup;
    //    arr.length = length;
    //    return arr;
    //}

    void grow(){
        import std.algorithm: max;
        size_t newSize = max(1, data.length * growFactor);
        size_t expandSize = newSize - data.length;
        if(data.length is 0){
            data = cast(T[])allocator.allocate(T.sizeof * newSize);
        }
        else{
            void[] a = cast(void[])data;
            allocator.reallocate(a, T.sizeof * newSize);
            data = cast(T[])a;
        }
    }
    void insert(T value){
        import std.algorithm.mutation;
        if(length == data.length){
            grow();
        }
        moveEmplace(value, data[length]);
        length += 1;
    }

    alias insertBack = insert;

    void emplaceBack(Args...)(auto ref Args args){
        if(length == size){
            grow();
        }
        data[length] = T(args);
        length += 1;
    }
    ref T access(size_t index){
        return (data)[index];
    }

    auto opIndex(){
        return opSlice();
    }

    auto opSlice(size_t start, size_t end){
        return data[start .. end];
    }
    auto opSlice(){
        return opSlice(0, length);
    }

    ref T opIndex(size_t index){
        return access(index);
    }

    void swap(size_t i1, size_t i2){
        static import std.algorithm.mutation;
        std.algorithm.mutation.swap(data[i1], data[i2]);
    }

    ref T back(){
        return access(length - 1);
    }

    void remove(size_t index){
        assert(index < length);
        if(index is length -1){
            removeLast();
        }
        else{
           swap(index, length - 1);
           removeLast();
        }
    }

    alias removeBack = removeLast;
    void removeLast(){
        length -= 1;
//        static if(isObject){
//            data[length - 1] = null;
//        }
//        else{
//            data[length - 1].destroy();
//        }
    }

    bool empty(){
        return length is 0;
    }
}
