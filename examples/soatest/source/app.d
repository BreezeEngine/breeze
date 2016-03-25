import std.stdio;
import breeze.util.soa;

enum size = 100000;

struct Vector3{
    float x, y, z;
}

struct Vector3Soa{
    float[size] x;
    float[size] y;
    float[size] z;
}

Vector3[size] createAos(){
    import std.random;
    Vector3[size] v;
    foreach(ref e; v){
        e.x = uniform(0,100);
        e.y = uniform(0,100);
        e.z = uniform(0,100);
    }
    return v;
}

Vector3Soa createSoa(){
    import std.random;
    auto v = Vector3Soa();
    foreach(ref e; v.x){
        e = uniform(0,100);
    }
    foreach(ref e; v.y){
        e = uniform(0,100);
    }
    foreach(ref e; v.z){
        e = uniform(0,100);
    }

    return v;
}

void testSoa(ref Vector3Soa soa, size_t size){
    float x=1, y=1, z=1;
    foreach(index; 0 .. size){
        x *= soa.x[index];
        y *= soa.y[index];
        z *= soa.z[index];
    }
}

void testSoa2(ref SOA!Vector3 soa, size_t size){
    float x=1, y=1, z=1;
    foreach(index; 0 .. size){
        x *= soa.x[index];
        y *= soa.y[index];
        z *= soa.z[index];
    }
}
void testSoa3(S)(ref S soa, size_t size)@unsafe{
    float x=1, y=1, z=1;
    foreach(index; 0 .. size){
        x *= soa.x[index];
        y *= soa.y[index];
        z *= soa.z[index];
    }
}

void testAos(A)(ref A aos, size_t size){
    float x=1, y=1, z=1;
    foreach(index; 0 .. size){
        x *= aos[index].x;
        y *= aos[index].y;
        z *= aos[index].z;
    }
}

void main(){
    import std.datetime;
    import std.conv : to;

    enum length = 100;

    auto aos = createAos;
    auto d1 = benchmark!(() => testAos(aos, size))(length)[0].to!Duration;
    writeln(d1);

    auto soa = createSoa;
    auto d2 = benchmark!(() => testSoa3(soa, size))(length)[0].to!Duration;
    writeln(d2);

    auto soa2 = SOA!(Vector3)(size);
    auto d3 = benchmark!(() => testSoa2(soa2, size))(length)[0].to!Duration;
    writeln(d3);
}
