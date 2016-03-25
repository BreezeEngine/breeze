module breeze.util.logger;



class Logger
{
    static import std.experimental.logger;
    private this() {
      l = new std.experimental.logger.FileLogger("test.log");

    }

    // Cache instantiation flag in thread-local bool
    // Thread local
    private static bool instantiated_;

    // Thread global
    private __gshared Logger instance_;

    static Logger get()
    {
        if (!instantiated_)
            {
            synchronized(Logger.classinfo){
                if (!instance_){
                    instance_ = new Logger();
                }
                instantiated_ = true;
            }
        }

        return instance_;
    }

    std.experimental.logger.Logger l;
    alias l this;
}
unittest{

    //Logger.get().logLevel = Log
    //Logger.get().error("Test");
}

