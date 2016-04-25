module breeze.concurrency.task;

struct Cell(R){
    shared R value = void;
    shared uint counter = 0;
    shared void set(R val){
        import core.atomic;
        atomicStore(value, val);
    }

    this(int _counter){
      counter = _counter;
    }

    shared R get(){
        import core.atomic;
        while(atomicLoad(counter) != 0){
            Fiber.yield;
        }
        return value;
    }
}

int add(int a, int b){
    return a+b;
}
int add(){
    return 42;
}
import containers.dynamicarray;

public struct Exit{}
public struct FiberTask{
    import core.thread;
    Fiber fiber;
    shared counter = 0;
}
public struct Task{
    void delegate() shared f;
}
public alias Message = int;
Task task(F, Args...)(F fn, auto ref Args args){
    auto t = Task();
    t.f = ()shared {
       fn(args);
    };
    return t;
}
import breeze.handlearray;
import core.thread;
import std.stdio;
DynamicArray!FiberTask work;
DynamicArray!FiberTask queuedWork;
void threadFunc(int numberOfWork){
    import std.concurrency;
    import std.stdio;
    bool isDone = false;
    while(!isDone){
        import std.range;
        foreach(_; iota(0, numberOfWork)){
            try{
                bool noMoreData = receiveTimeout(dur!"seconds"(0),
                        (Exit e) => isDone = true,
                        (Task t){
                            work.insert(FiberTask(new Fiber((){
                                t.f();
                            })));
                        }
                );
                if(noMoreData) break;
            }
            catch(OwnerTerminated e){
                isDone = true;
            }
        }
        if(!queuedWork.empty){
            import std.algorithm.iteration;
            foreach(index, FiberTask e; queuedWork[].enumerate){
                e.fiber.call();
                if(e.fiber.state is Fiber.State.TERM){
                    queuedWork.remove(index);
                }
            }
        }
        if(!work.empty){
            writeln("work");
            auto f = work[work.length -1];
            f.fiber.call();
            if(f.fiber.state is Fiber.State.HOLD){
                queuedWork.insert(f);
            }
            work.remove(work.length - 1);
        }
    }
}
import std.concurrency: spawn, Tid, send;
struct TaskPool{
    import containers.dynamicarray;
    import std.parallelism: defaultPoolThreads;
    DynamicArray!Tid threads;
    uint numberOfThreads;
    this(uint _numberOfThreads){
        numberOfThreads = _numberOfThreads;
        import std.range;
        foreach(index; iota(0, numberOfThreads)){
            threads.insert(spawn(&threadFunc, 10));
        }
    }

    auto submit(F, Args...)(F fn, auto ref Args args){
        import std.random;
        auto gen = Random(unpredictableSeed);
        auto a = uniform(0, numberOfThreads, gen);
        import std.traits;
        static if(is(ReturnType!F == void)){
            return submitWorkVoid(threads[a], fn, args);
        }
        else{
            return submitWork(threads[a], fn, args);
        }
    }
}

TaskPool* taskPool()
{
    import std.concurrency : initOnce;
    import std.parallelism: defaultPoolThreads;
    __gshared TaskPool* pool;
    return initOnce!pool({
            auto p = new TaskPool(defaultPoolThreads);
            return p;
            }());
}

auto submitWork(F, Args...)(Tid tid, F fn, auto ref Args args){
    import std.traits: ReturnType;
    alias R = ReturnType!F;
    shared auto c = Cell!R(1);
    auto wrappedFn = (shared ref Cell!R cell) shared{
        import core.atomic;
        R val = fn(args);
        cell.set(val);
        atomicOp!"-="(cell.counter, 1);
    };
    tid.send(task(wrappedFn, c));
    R val = c.get();
    return val;
}
import std.traits: ReturnType;
void submitWorkVoid(F, Args...)(Tid tid, F fn, auto ref Args args)
if(is(ReturnType!F == void)){
    auto wrappedFn = () shared{
        import core.atomic;
        fn(args);
    };
    tid.send(task(wrappedFn));
}
unittest{

import core.thread;
//taskPool.submit((){
//    writeln("test");
//    auto r = taskPool.submit((){
//        Thread.sleep(dur!"seconds"(3));
//        return 42;
//    });
//    writeln("r ", r);
//});
//Thread.sleep(dur!"seconds"(5));
//    import std.range;
//    auto t = spawn(&threadFunc, 10);
//    shared int i = 5;
//    shared auto c = Cell!int();
//    auto t1 = task((shared ref Cell!int cell){
//        c.set(42);
//    }, c);
//    tas
//    foreach(index; iota(0,1)){
//        t.send(task((int index){
//            writeln("task ", index, " begin");
//            Fiber.yield;
//            writeln("task ", index, " end");
//        }, index));
//    }


//    t.send(task((){
//          writeln("task start");
//          writeln("task val ", submitWork(t, (){
//              Thread.sleep(dur!"seconds"(3));
//              return 42;
//          }));
//    }));
//    Thread.sleep(dur!"seconds"(5));
//    t.send(Exit());
    //    auto t = task((){
    //        writeln("Starting Task 1");
    //        auto t1 = task((){
    //            writeln("Starting Task 2");
    //            Thread.sleep(dur!"seconds"(5));
    //            writeln("end Task 2");
    //            return 42;
    //        });
    //        taskPool.put(t1);
    //        int i = t1.yieldForce;
    //        writeln("end Task 2 inside task 1");
    //        return i;
    //    });
    //    taskPool.put(t);
    //    foreach(index; iota(0, 2)){
    //      auto t2 = task((int i){
    //          writeln("start test ", i);
    //          Thread.sleep(dur!"seconds"(4));
    //          writeln("end test ", i);
    //      }, index);
    //     taskPool.put(t2);
    //    }
    //    int i = t.yieldForce;
    //    writeln(i);

}
