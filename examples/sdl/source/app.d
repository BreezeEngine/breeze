import std.stdio;

void main()
{
		import std.meta;
		import breeze.graphics.opengl.shader;
		import breeze.graphics.opengl.types;
		import breeze.graphics.opengl.buffer;
		import breeze.graphics.primitives: Cube;
		import std.conv;
		import std.range;
		import breeze.math.vector;
		import breeze.math.matrix;
		import std.math;
		import std.string;
		import breeze.input;
		import derelict.opengl3.gl3;
		import derelict.glfw3.glfw3;
		import derelict.sdl2.sdl;
//		auto window = GLFWWindow(720, 480, "Test");
//		window.mainLoop((ref w){
//				writeln(w.keyinputs[]);
//				w.keyinputs.clear;
//		});
		auto input = Input();
		auto window = Window("Test", 720, 480, &input);
		auto context = window.createGLContext;
		auto im = InputMap!(
				Axis!(AxisState("Forward", -1, 1)),
				Action!("Escape"))();
		im.action!"Escape"(Key.q);
		im.axis!"Forward"(Key.w, 1);
		im.axis!"Forward"(Key.s, -1);
		window.mainLoop((input){
				if(im.getAction!(KeyState.pressed, "Escape")(*input)){
						writeln("Down Escape");
				}
				if(im.getAction!(KeyState.released, "Escape")(*input)){
						writeln("Rel Escape");
				}
				if(im.getAction!(KeyState.holding, "Escape")(*input)){
						writeln("holding Escape");
				}

				writeln(im.getAxis!"Forward"(*input));
				input.reset;
		});
//		im.action!"Escape"((ref KeyInput keyinput){
//				return
//						keyinput.key is Key.q &&
//						!keyinput.repeat &&
//						keyinput.keystate is KeyState.pressed;
//		});
//		im.axis!"Forward"(Key.w, 1);
//		im.axis!"Forward"(Key.s, -1);
//		struct Vertex{
//				Vec3f position;
//				Vec3f normal;
//				Vec2f uv;
//		}
//
//		struct Uniforms{
//				Mat4f uproj;
//				Mat4f uview;
//				Mat4f umodel;
//		}
//
//		alias VertexInput = Vertex;
//
//		struct VertexOutput{
//				Vec3f out_color;
//		}
//
//		alias FragmentInput = VertexOutput;
//
//		struct FragmentOutput{
//				Vec4f frag_color;
//		}
//
//
//		string vertexBody = q{
//				void main(){
//						gl_Position = uproj * uview * umodel * vec4(position, 1);
//						out_color = vec3(uv, 0);
//				}
//		}.outdent;
//
//		auto vs = VertexShader!(VertexInput, VertexOutput, Uniforms)(vertexBody);
//
//		static immutable string fragmentBody = q{
//				void main(){
//						frag_color = vec4(out_color, 1);
//				}
//		}.outdent;
//
//		auto fs = FragmentShader!(FragmentInput, FragmentOutput, Uniforms)(fragmentBody);
//
//		auto shader = createTypeSafeShader(vs, fs);
//
//		auto vertexBuffer = createVertexBuffer(Cube.data[]);
//		auto ebo = createElementBuffer(Cube.indices[]);
//
//		//auto view = Mat4f.identity;
//		import breeze.math.units;
//		auto proj = projection(Radians(Degrees(102)).value, 4.0f/3.0f, 0.1f, 100);
//		float frame = 0.0f;
//		import breeze.util.obj;
//		import containers.dynamicarray;
//		DynamicArray!Mesh mesh = parsObj("/home/maik/projects/breeze/bin/akm.obj");
//		auto vertexBuffer2 = createVertexBuffer!Mesh(mesh[]);
//		w.mainLoop((input){
//				import std.algorithm.iteration;
//				im.update(input.keyinputs);
//				if(im.getAction!"Escape"){
//						writeln("Escape");
//				}
//				float f = im.getAxis!"Forward" ;
//				writeln(f);
////				if(!input.keyinputs[].filter!(
////						k => k.key is Key.q &&
////						k.keystate is KeyState.pressed &&
////						!k.repeat).empty){
////						writeln("q pressed unique");
////				}
////				if(!input.keyinputs[].filter!(k => k.key is Key.q && k.keystate is KeyState.released).empty){
////						writeln("q released");
////				}
//				auto view = lookAt(Vec3f(40, 0, 0), Vec3f(0, 2, 0), Vec3f(0, 1, 0));
//				draw(shader, vertexBuffer2, DrawMode.Triangles, Uniforms(proj, view, rotX(frame)));
//				frame += 0.01f;
//				foreach(ref r; im.actionResults){
//						r = false;
//				}
//				foreach(ref r; im.axisResults){
//						r = 0;
//				}
//				import derelict.sdl2.sdl;
//				SDL_Delay(1000);
//		});
}
