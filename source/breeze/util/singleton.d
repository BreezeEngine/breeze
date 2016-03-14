module breeze.util.singleton;
import std.stdio;
class Singleton(T)
{
    import std.container: Array;
    private this() {}

    // Cache instantiation flag in thread-local bool
    // Thread local
    private static bool instantiated_;

    // Thread global
    private __gshared Singleton!T instance_;

    static Singleton!T get()
    {
        if (!instantiated_)
            {
            synchronized(Singleton!T.classinfo){
                if (!instance_){
                    instance_ = new Singleton!T();
                }
                instantiated_ = true;
                instance_.tls.insertBack(&instance_.value);
            }
        }

        return instance_;
    }
    __gshared Array!(T*) tls;
    static T value;
}
unittest{
    import std.concurrency;
 //   import core.thread;
 //   auto s = Singleton!int.get();
 //   foreach(index; 0..10){
 //       spawn((int a){
 //           auto s = Singleton!int.get();
 //           s.value = a;
 //           writeln(&s.value);
 //       }, index);
 //   }
//    Thread.sleep( dur!("seconds")( 1 ) );
//    writeln("--");
//    foreach(p; s.tls){
//    }
}
