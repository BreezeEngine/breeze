module breeze.handlearray;
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
struct Array(T)
if(!is(T == class))
{
    import std.experimental.allocator;
    import std.experimental.allocator.mallocator;
    IAllocator alloc;
    T[] data;

    size_t size = 0;
    size_t length = 0;

    ArrayRange!(Array!T) range(){
        return ArrayRange!(Array!T)(&this);
    }
    int growFactor = 2;
    Array init(){
        return Array!T(1);
    }
    this(size_t size, IAllocator allocator = allocatorObject(Mallocator.instance)){
        assert(size > 0, "Size should not be 0");
        alloc = allocator;
        data = alloc.makeArray!T(size);
        this.size = size;
        length = 0;
        growFactor = 2;
    }
    //@disable this();
    ~this(){
        if(alloc !is null){
            alloc.dispose(data);
        }
    }
    void grow(){
        import std.algorithm: max;
        size_t newSize = max(1,size * growFactor);
        size_t expandSize = newSize - size;
        if(alloc is null){
            alloc = allocatorObject(Mallocator.instance);
            data = alloc.makeArray!T(newSize);
        }
        else{
            alloc.expandArray(data, expandSize);
        }
        size = newSize;
    }
    void insert(T value){
        import std.algorithm.mutation;
        if(length == size){
            grow();
        }
        data[length] = value;
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
    ArrayRange!Array opIndex(){
        return ArrayRange!Array(&this);
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
        data[length].destroy();
    }

    bool empty(){
        return length is 0;
    }
}
struct Handle(T){
    import breeze.owned;
    OwnedRef!(HandleImpl!T) handleImpl;
    bool expired(){
        return handleImpl.expired;
    }
    ref T get(){
        if(expired) throw new Error("Access to expired Handle.");
        return handleImpl.get().get();
    }
}
struct HandleImpl(T){
    size_t index;
    HandleArray!T* array;
    ref T get(){
      return array.get(index);
    }
}
struct HandleArray(T){
    import breeze.owned;
    static import std.container;
    std.container.Array!T container;
    Array!(Owned!(HandleImpl!T)) handles;
    this(size_t s){
      handles = Array!(Owned!(HandleImpl!T))(1);
    }
    auto opIndex(){
        return container[];
    }

    void insertBack(T value){
        container.insertBack(value);
        handles.insertBack(Owned!(HandleImpl!T).init);
    }
    auto getHandle(size_t index){
        if(!handles[index].expired){
            return Handle!T(handles[index].getRef());
        }
        else{
            auto o = Owned!(HandleImpl!T)(index, &this);
            auto w = o.getRef();
            handles[index] = o.release;
            return Handle!T(w);
        }
    }
    ref T get(size_t index){
        return container[index];
    }
    void swap(size_t first, size_t second){
        import std.algorithm.mutation;
        import std.algorithm: max;
        if(first == second || container.length < 1 || 
                max(first,second) < (container.length -1)) return;
        swap(container[first], container[second]);
        if(!handles[first].expired && !handles[second].expired){
            swap(handles[first], handles[second]);
            handles[first].get.index= first;
            handles[second].get.index = second;
        }
        else if (!handles[first].expired){
            handles[second] = move(handles[first]);
            handles[second].get.index = second;
        }
        else if (!handles[second].expired){
            handles[first] = move(handles[second]);
            handles[first].get.index = first;
        }
    }

    void transfer(Handle!T handle){
        import std.algorithm.mutation;
        if(handle.expired || handle.handleImpl.array is &this) return;
        size_t index = handle.handleImpl.index;
        insertBack(move(handle.handleImpl.array.get(index)));
        handles.insertBack(handles[index].release);
        size_t lastIndex = handles.length - 1;
        handles[lastIndex].get.index = lastIndex;
    }

    //void remove(Handle!T handle){
    //    if(handle.expired || handle.array is &this) return;
    //}
    void remove(size_t index){
        swap(index, container.length - 1);
        container.removeBack();
        handles.removeLast();
    }
}
