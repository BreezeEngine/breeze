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

    bool isDone(){
        import core.atomic;
        return atomicLoad(counter) is 0;
    }

    shared R get(){
        import core.atomic;
        if(Fiber.getThis){
            while(atomicLoad(counter) != 0){
                Fiber.yield;
            }
        }
        else{
            while(atomicLoad(counter) != 0){
            }
        }
        return value;
    }
//    import std.datetime;
//    shared R get(DateTime time){
//        import core.atomic;
//        auto startTime = Clock.currTime;
//        if(Fiber.getThis){
//            while(atomicLoad(counter) != 0){
//                Fiber.yield;
//            }
//        }
//        else{
//            while(atomicLoad(counter) != 0 && (Clock.currTime - startTime) < time){
//            }
//        }
//        return value;
//    }
}
//
//int add(int a, int b){
//    return a+b;
//}
//int add(){
//    return 42;
//}
//import containers.dynamicarray;
//
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
Task task(alias fn, Args...)(auto ref Args args){
    auto t = Task();
    t.f = () shared{
       fn(args);
    };
    return t;
}
import core.thread;
import std.stdio;

import breeze.util.array;
struct LocalTaskQueue{
    import breeze.util.array;
    import std.experimental.allocator;
    import breeze.memory;
    Array!(Box!Fiber) work;
    Array!(Box!Fiber) queuedWork;

    uint maxNumberOfWork = 1;
    bool shouldTerminate = false;

    this(uint numberOfWork){
        maxNumberOfWork = numberOfWork;
    }

    void receiveWork(){
        import std.range;
        import std.concurrency;
        import std.algorithm.mutation;
        foreach(_; iota(0, maxNumberOfWork)){
            try{
                bool noMoreData = receiveTimeout(dur!"seconds"(0),
                        (Exit e){
                            shouldTerminate = true;
                        },
                        (Task t){
                            auto f = box!Fiber((){
                                t.f();
                            });
                            work.insert(f.move);
                        }
                );
                if(noMoreData) break;
            }
            catch(OwnerTerminated e){
                shouldTerminate = true;
            }
        }
    }

    void doWork(){
        import std.range;
        import std.algorithm.mutation;
        if(!queuedWork.empty){
            import std.algorithm.iteration;
            foreach(index, ref f; queuedWork){
                if(f.state !is Fiber.State.TERM){
                    f.call();
                }
                if(f.state is Fiber.State.TERM){
                    queuedWork.remove(index);
                }
            }
        }
        if(!work.empty){
           auto f = work[work.length -1].move;
           if(f.state !is Fiber.State.TERM){
                f.call();
           }
           if(f.state is Fiber.State.HOLD){
                queuedWork.insert(f.move);
           }
           work.remove(work.length - 1);
        }
    }

    void start(){
        while(!shouldTerminate){
            receiveWork();
            doWork();
        }
    }
}
import std.concurrency: spawn, Tid, send;
struct TaskPool{
    import std.parallelism: defaultPoolThreads;
    Array!Tid threads;
    uint numberOfThreads;
    this(uint _numberOfThreads){
        numberOfThreads = _numberOfThreads;
        import std.range;
        foreach(index; iota(0, numberOfThreads)){
            threads.insert(spawn((){
                auto queue = LocalTaskQueue(10);
                queue.start();
            }));
        }
    }

    ~this(){
        foreach(tid; threads){
            tid.send(Exit());
        }
    }

}

auto submit(alias fn, Args...)(ref TaskPool pool, auto ref Args args){
    import std.random;
    auto gen = Random(unpredictableSeed);
    auto a = uniform(0, pool.numberOfThreads, gen);
    import std.traits;
    static if(is(ReturnType!(typeof(fn)) == void)){
        return submitWorkVoid(pool.threads[a], fn, args);
    }
    else{
        return submitWork(pool.threads[a], fn, args);
    }
}
//TaskPool* taskPool()
//{
//    import std.concurrency : initOnce;
//    import std.parallelism: defaultPoolThreads;
//    __gshared TaskPool* pool;
//    return initOnce!pool({
//            auto p = new TaskPool(defaultPoolThreads);
//            return p;
//            }());
//}
//
auto submitWork(F, Args...)(Tid tid, F fn, auto ref Args args){
    import std.traits: ReturnType;
    alias R = ReturnType!F;
    shared auto c = new Cell!R(1);
    import std.typecons;
    auto wrappedFn = (shared Cell!R* cell) shared{
        import core.atomic;
        R val = fn(args);
        cell.set(val);
        atomicOp!"-="(cell.counter, 1);
    };
    tid.send(task!wrappedFn(c));
    return c;
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
//unittest{
//
//import core.thread;
////taskPool.submit((){
////    writeln("test");
////    auto r = taskPool.submit((){
////        Thread.sleep(dur!"seconds"(3));
////        return 42;
////    });
////    writeln("r ", r);
////});
////Thread.sleep(dur!"seconds"(5));
////    import std.range;
////    auto t = spawn(&threadFunc, 10);
////    shared int i = 5;
////    shared auto c = Cell!int();
////    auto t1 = task((shared ref Cell!int cell){
////        c.set(42);
////    }, c);
////    tas
////    foreach(index; iota(0,1)){
////        t.send(task((int index){
////            writeln("task ", index, " begin");
////            Fiber.yield;
////            writeln("task ", index, " end");
////        }, index));
////    }
//
//
////    t.send(task((){
////          writeln("task start");
////          writeln("task val ", submitWork(t, (){
////              Thread.sleep(dur!"seconds"(3));
////              return 42;
////          }));
////    }));
////    Thread.sleep(dur!"seconds"(5));
////    t.send(Exit());
//    //    auto t = task((){
//    //        writeln("Starting Task 1");
//    //        auto t1 = task((){
//    //            writeln("Starting Task 2");
//    //            Thread.sleep(dur!"seconds"(5));
//    //            writeln("end Task 2");
//    //            return 42;
//    //        });
//    //        taskPool.put(t1);
//    //        int i = t1.yieldForce;
//    //        writeln("end Task 2 inside task 1");
//    //        return i;
//    //    });
//    //    taskPool.put(t);
//    //    foreach(index; iota(0, 2)){
//    //      auto t2 = task((int i){
//    //          writeln("start test ", i);
//    //          Thread.sleep(dur!"seconds"(4));
//    //          writeln("end test ", i);
//    //      }, index);
//    //     taskPool.put(t2);
//    //    }
//    //    int i = t.yieldForce;
//    //    writeln(i);
//
//}
