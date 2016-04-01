module breeze.network.network;
import std.stdio;

struct PacketHeader{
    ulong hash;
    Command command;
}

enum Command{
    Connect,
    Disconnect,
    KeepAlive
}
struct Peer{
    import std.socket;
    import std.container: Array;
    import breeze.util.soa;

    Array!RemotePeer remoteClients;

    SOA!RemotePeer remotePeers;

    UdpSocket socket;
    Address address;

    union HeaderUnion{
        ubyte[PacketHeader.sizeof] buffer;
        PacketHeader header;
    }
    HeaderUnion header;
    this(ushort port){
        socket = new UdpSocket(AddressFamily.INET);
        socket.blocking = false;
        address = new InternetAddress(port);
        socket.bind(address);
    }


    void poll(){
        import std.algorithm.searching;
        import std.datetime;
        import std.range;
        long res = 1;
        while(res > 0){
            Address _address;
            res = socket.receiveFrom(header.buffer, _address);
            auto packetHeader = &header.header;
            if(res <= 0) return;
            if(packetHeader.hash !is typeid(Peer).toHash) return;

            final switch(packetHeader.command) with (Command){
            case Connect:
                if(!remotePeers.address.canFind!((c) => c is _address)){
                    auto peer = RemotePeer(_address, Clock.currTime);
                    remotePeers.insertBack(peer);
                    writeln(remotePeers.length);
                }
                break;
            case Disconnect:
                break;
            case KeepAlive:
                auto index = remotePeers.address.countUntil!((ref adr) => adr is _address) - 1;
                if(index >= 0){
                    remotePeers.lastReceivedPacket[index] = Clock.currTime;
                }
                break;
            }
        }
    }

    void connect(ref Peer peer){
        header.header = (PacketHeader(typeid(Peer).toHash, Command.Connect));
        socket.sendTo(header.buffer, peer.address);
    }
}

struct RemotePeer{
    import std.socket;
    import std.datetime;
    Address address;
    SysTime lastReceivedPacket;
}

unittest{
    import std.socket;
    import std.stdio;
    import breeze.util.soa;
    import std.datetime;
    import std.experimental.allocator;
    import std.experimental.allocator.mallocator;
    auto p0 = Peer(4239);
    auto p1 = Peer(4240);
    auto p2 = Peer(4241);
    auto p3 = Peer(4242);

    Address[] adr = Mallocator.instance.makeArray!(Address)(5);
    adr[0] = new InternetAddress(1234);
    adr[1] = new InternetAddress(1234);
    adr[2] = new InternetAddress(1234);
    writeln(adr.length);
    SOA!RemotePeer remotePeers;
    //p3.poll;
    remotePeers.insertBack(RemotePeer(new InternetAddress(1234), Clock.currTime));
    remotePeers.insertBack(RemotePeer(new InternetAddress(1234), Clock.currTime));
    remotePeers.insertBack(RemotePeer(new InternetAddress(1234), Clock.currTime));
    remotePeers.insertBack(RemotePeer(new InternetAddress(1234), Clock.currTime));
    remotePeers.insertBack(RemotePeer(new InternetAddress(1234), Clock.currTime));

    import std.container;
    //writeln("end: ", (Array!int).sizeof);


    //    p2.poll;
    //    writeln(p2.remoteClients[]);
    //    p2.poll;
}
