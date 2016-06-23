module breeze.handlearray;
import std.stdio;
import breeze.util.array;
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
