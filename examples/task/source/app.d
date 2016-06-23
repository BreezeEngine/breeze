//import breeze.concurrency.task;
//import core.thread;
//import breeze.util.array;
//import breeze.memory;

interface Bar{
}
class Foo: Bar{
    int i;
    int j;
    this(int _i, int _j){
    }
}
void main(){
    import std.stdio;
    import std.algorithm.mutation;
    import std.process;
    import std.datetime;
    import breeze.memory;
//    auto test = box!(Closure!(FnType!(void, void), (int capturedVar){
//        writeln(capturedVar);
//    }))(5);
//    test.call();
//    testFunc!printCapturedVars();
//
    import breeze.fn;
    import std.stdio;
    import std.experimental.allocator.mallocator;
    import std.experimental.allocator;
    auto b = box!Foo(1, 2);
//    Box!(Function!void) printCapturedInt = fnboxed!(Function!void)((int captured){
//        writeln(captured);
//    }, 42);
//    printCapturedInt.call();
//
//    Box!(Function!(int, int)) add = fnboxed!(Function!(int, int))((int a, int captured){
//        return a + captured;
//    }, 42);
//    writeln(add.call(1));
    auto boxedInt = box(42);
    Box!(Function!(int, int)) addBoxed = fnboxed!(Function!(int, int))((int a, Box!(int)* captured){
        return a + captured;
    }, boxedInt.move);
//    auto test2 = Box!(Function!void)(test1.move);
//    writeln("TEST ", &test1.value);
    //test2.call();
    //auto test2 = Box!(Function!(void, void))(test1.move());
    //test1.call();
    //auto test1 = new Closure!(Function!(void, void), (){
    //    writeln("empty");
    //})();
    //test1.call();
   //import std.algorithm.mutation;
   //auto test3 = Box!(Function!(void))(test1.move);
   //test3.call();
   //auto val = Mallocator.instance.make!(Closure!(FnType!(void, void), (){
   //    writeln("empty");
   //}))();
   //writeln(&val);
   //Function!void voidf = val;
   //Function!void voidf2 = val;
   //Function!void voidf3 = val;
   //writeln(&voidf);
   //writeln(&voidf2);
   //writeln(&voidf3);
   
//    auto start = Clock.currTime;
//    auto s = (execute(["dub", "build :task"], null, Config.none, size_t.max, "/home/maik/projects/breeze/"));
//    auto end = Clock.currTime;
//    writeln(end - start);
//    auto b = box(2);
//    auto d = (){
//        auto b1 = b.move;
//    };
//    auto tp = TaskPool(3);
//    const arr = Array!int(5);
//    auto r = tp.submit!((){
//        auto c = tp.submit!((){
//            auto d = tp.submit!((){
//                writeln("executing on ", Thread.getThis.id);
//                return 42;
//            });
//            writeln(d.get);
//            writeln("executing on ", Thread.getThis.id);
//            return 42;
//        });
//        writeln(c.get);
//        writeln("executing on ", Thread.getThis.id);
//        return 10;
//    });
//    writeln(r.get);
//    import std.algorithm.mutation;
}
