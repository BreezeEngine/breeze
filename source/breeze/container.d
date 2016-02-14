struct Array(T)
if(!is(T == class))
{
    import std.experimental.allocator;
    import std.experimental.allocator.mallocator;
    IAllocator alloc;
    T[] data;

    size_t size = 1;
    size_t length = 0;

    ArrayRange!(Array!T) range(){
        return ArrayRange!(Array!T)(&this);
    }
    int growFactor;
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
        size_t newSize = size * growFactor;
        size_t expandSize = newSize - size;
        alloc.expandArray(data, expandSize);
        size = newSize;
    }
    void insertBack(T value){
        import std.algorithm.mutation;
        if(length == size){
            grow();
        }
        data[length] = move(value);
        length += 1;
    }
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
    ref T opIndex(size_t index){
        return access(index);
    }
    void swap(size_t i1, size_t i2){
        import std.algorithm.mutation;
        swap(data[i1], data[i2]);
    }
    void removeLast(){
        length -= 1;
        data[length].destroy();
    }
    @disable this(this);
}
