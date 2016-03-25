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
        Address _address;
        if(socket.receiveFrom(header.buffer, _address) is 0 || _address is null) return;

        auto packetHeader = &header.header;
        if(packetHeader.hash == typeid(Peer).toHash){
            if(packetHeader.command is Command.Connect){
                if(!remotePeers.address.canFind!((c) => c == _address)){
                    remotePeers.insertBack(RemotePeer(_address, Clock.currTime));
                }
            }
        else if(packetHeader.command is Command.KeepAlive){
                auto arr = remotePeers.address.enumerate(0).find!((t){
                    return t.value == _address;
                });
                if(arr.length == 1){
                    remotePeers.lastReceivedPacket[arr[0][0]] = Clock.currTime;
                }
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

    import std.datetime;
    auto p1 = Peer(4240);
    auto p2 = Peer(4241);
    auto p3 = Peer(4242);

    p1.connect(p2);
    p2.poll;
    p3.connect(p2);
    p2.poll;
    writeln(p2.remotePeers.address);
    //    writeln(p2.remoteClients[]);
    //    p2.poll;
    //    writeln(p2.remoteClients[]);
    //    p2.poll;
}
