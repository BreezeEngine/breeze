
//struct with junk data
struct Foo{
    float[30] xy;
    float t;
    float f = 42;
    string name = "test";
    float s;
    float [50] z;
    float* ptr;
}

float testSoa2(S)(ref S soa){
    float sum = 0;
    foreach(index; 0 .. soa.length){
        sum += soa.f[index];
    }
    return sum * sum;
}

float testAos2(A)(ref A aos){
    float sum = 0;
    foreach(index; 0 .. aos.length){
        sum += aos[index].f;
    }
    return sum * sum;
}

struct Vector3{
    float x=1, y=2, z=3;
}

Vector3 testAos(A)(ref A aos){
    float x=0;
    float y=0;
    float z=0;

    foreach(index; 0 .. aos.length){
        x += aos[index].x;
        y += aos[index].y;
        z += aos[index].z;
    }
    return Vector3(x, y, z);
}

Vector3 testSoa(S)(ref S soa){
    float x=0;
    float y=0;
    float z=0;

    foreach(index; 0 .. soa.length){
        x += soa.x[index];
        y += soa.y[index];
        z += soa.z[index];
    }
    return Vector3(x, y, z);
}

void main(string[] args){
    import std.stdio;
    import std.container: Array;
    import std.datetime;
    import std.conv : to;
    import std.exception: enforce;
    import breeze.util.soa;

    auto size = 1000000;
    enum length = 1000;

    writeln("benchmarking complete access");
    auto aosVec = Array!Vector3();
    foreach(_; 0 .. size){
        aosVec.insertBack(Vector3());
    }

    Vector3 v;
    float f;
    auto res = Vector3(1* size, 2* size, 3* size);

    auto d1 = benchmark!({v = testAos(aosVec);})(length)[0].to!Duration;
    enforce(v == res);
    writeln("AoS: ", d1);

    auto soaVec = SOA!Vector3(size);
    foreach(index; 0 .. size){
        soaVec.x[index] = 1;
        soaVec.y[index] = 2;
        soaVec.z[index] = 3;
    }
    auto d2 = benchmark!({v = testSoa(soaVec);})(length)[0].to!Duration;
    enforce(v == res);
    writeln("SoA: ", d2);

    import std.container;
    import containers.dynamicarray;
    auto soaVec2 = SOA2!(Vector3, DynamicArray)();
    foreach(_; 0 .. size){
        soaVec2.insertBack(Vector3());
    }

    auto d22 = benchmark!({v = testSoa(soaVec2);})(length)[0].to!Duration;
    enforce(v == res);
    writeln("SoA2: ", d22);

//    writeln("benchmarking partial access");
//    auto aos = Array!(Foo)();
//    foreach(_; 0 .. size){
//        aos.insertBack(Foo());
//    }
//
//    auto d3 = benchmark!({f = testAos2(aos);})(length)[0].to!Duration;
//    enforce(f > 1e13);
//    writeln("AoS: ", d3);
//
//    auto soa2 = SOA2!(Foo, Array)(size);
//    foreach(index; 0 .. size){
//        soa2.f[index] = 42;
//    }
//    auto d4 = benchmark!({f = testSoa2(soa2);})(length)[0].to!Duration;
//    enforce(f > 1e13);
//    writeln("SoA: ", d4);
}
