module breeze.input;
import std.stdio;
import option;


import derelict.sdl2.sdl;

int[keycodes.length] genKeycodesLookup(){
		int[keycodes.length] lookUpTable;
		foreach(index, keycode; keycodes){
				lookUpTable[index] = keycode;
		}
		return lookUpTable;
}
enum keycodesLookup = genKeycodesLookup;

int[int] genKeycodeHash(){
		import std.range: iota;
		int[int] keyHash;
		foreach(index; iota(0, 236)){
				keyHash[keycodes[index]] = index;
		}
		return keyHash;
}

enum keycodeHash = genKeycodeHash();

struct GLContext{
		SDL_GLContext context;
}
struct Window{
		import breeze.math.vector;
		import derelict.sdl2.sdl;
		import derelict.opengl3.gl3;
		SDL_Window* handle;
		Input* input;
		this(string title, int width, int height, Input* _input){
				DerelictSDL2.load();
				handle = SDL_CreateWindow(title.ptr, 0, 0, width, height, SDL_WINDOW_OPENGL);
				input = _input;
		}
		bool shouldExit = false;

		GLContext createGLContext(){
				DerelictGL3.load();
				auto sdlc = SDL_GL_CreateContext(handle);
				DerelictGL3.reload();
				return GLContext(sdlc);
		}

		~this(){
				SDL_DestroyWindow(handle);
		}

		void setWindowPosition(Vec2i pos){
				SDL_SetWindowPosition(handle, pos.x, pos.y);
		}

		Vec2i getWindowPosition(){
				int x, y;
				SDL_GetWindowPosition(handle, &x, &y);
				return Vec2i(x, y);
		}

		void moveWindow(Vec2i dir){
				auto pos = getWindowPosition();
				setWindowPosition(pos + dir);
		}

		void close(){
				shouldExit = true;
		}

		void mainLoop(void delegate(Input* input) f){
				while(!shouldExit){
						SDL_PumpEvents();
						input.poll();
						foreach(ref ws; input.windowStates){
								if(SDL_GetWindowID(handle) is ws.handle){
										shouldExit = true;
								}
						}
						glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
						glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
						f(input);
						SDL_GL_SwapWindow(handle);
				}
		}
}


struct KeyInput{
		Key key;
		KeyState keystate;
		uint modifier;
		uint time;
}

struct Input{
		uint currentWindow;
		KeyState[5] mouseKeys;
		import std.container.array;
		struct WindowState{
				uint handle;
				bool shouldClose;
		}
		Array!WindowState windowStates;
		//struct KeyData(Keys){
		//		enum length = __traits(allMembers, Keys).length;
		//		bool[length] keysPressed;
		//		bool[length] keysReleased;
		//		bool[length] keysHolding;
		//}
		//KeyData!Key keyboardData;
		Array!KeyInput keyinputs;
		void poll(){
				SDL_Event event;
				while(SDL_PollEvent(&event)){
						
						if(event.type is SDL_QUIT){
								windowStates.insert(WindowState(currentWindow, true));
						}
						if(event.type is SDL_WINDOWEVENT){
								if(event.window.event is SDL_WINDOWEVENT_FOCUS_GAINED){
										currentWindow = event.window.windowID;
								}
						}
						if(event.type is SDL_KEYDOWN || event.type is SDL_KEYUP){
								if(!event.key.repeat){
										KeyInput keyinput = {
												key:cast(Key)keycodeHash[event.key.keysym.sym],
												keystate:cast(KeyState)event.key.state,
												time:event.key.timestamp,
												modifier:event.key.keysym.mod
										};
										keyinputs.insert(keyinput);
									//	auto keystate = cast(KeyState)event.key.state;
									//	auto key = cast(Key)keycodeHash[event.key.keysym.sym];
									//	if(keystate is KeyState.pressed){
									//			keyboardData.keysPressed[key] = true;
									//			keyboardData.keysHolding[key] = true;
									//	}
									//	if(keystate is KeyState.released){
									//			keyboardData.keysHolding[key] = false;
									//			keyboardData.keysReleased[key] = true;
									//	}
								}
						}
						if(event.type is SDL_MOUSEBUTTONDOWN){
								mouseKeys[event.button.button - 1] = KeyState.pressed;
						}
						if(event.type is SDL_MOUSEBUTTONUP){
								mouseKeys[event.button.button - 1] = KeyState.released;
						}
						if(event.type is SDL_MOUSEWHEEL){
						}
						if(event.type is SDL_MOUSEMOTION){
						}
				}
		}
		void reset(){
				keyinputs.clear;
		}
}

Option!Key getKeyFromString(string keyName){
		import std.string: toLower;
		foreach(_keyName; __traits(allMembers, Key)){
				if(keyName.toLower is _keyName){
						return some(__traits(getMember, Key, _keyName));
				}
		}
		return none!Key;
}

struct AxisState{
		string name;
		int min;
		int max;
}
struct Axis(_names...){
		import std.meta: allSatisfy;
		enum isAxisState(alias as) = is(typeof(as) == AxisState);
		static assert(allSatisfy!(isAxisState, _names), "All types must be of type AxisState");
		alias names = _names;
}
struct Action(_names...){
		alias names = _names;
}

auto varOr(Vals...)(Vals vals){
		static if(vals.length == 1){
				return vals[0];
		}
		else{
				return vals[0] | varOr(vals[1 .. $]);
		}
}
struct InputMap(Axis,Action){
		import option;
		import std.container: Array;

		import std.typecons;
		Array!(Tuple!(KeyMatch, int))[Axis.names.length] axisBindings;
		Array!KeyMatch[Action.names.length] actionBindings;
		int[Axis.names.length] axisResults;

		bool[Action.names.length] actionPressed;
		bool[Action.names.length] actionHolding;
		bool[Action.names.length] actionReleased;

		int[Axis.names.length] axisDown;

		void reset(){
				import std.range: iota;
				foreach(index; iota(0, Action.names.length)){
						actionPressed[index] = false;
						actionReleased[index] = false;
				}
		}

		void update(Array!KeyInput keyinputs){
				foreach(keyinput; keyinputs){
						foreach(index, actionKeys; actionBindings){
								foreach(actionKey; actionKeys){
										if(actionKey.key is keyinput.key && actionKey.keymod is keyinput.modifier){
												if(keyinput.keystate is KeyState.pressed){
														actionPressed[index] = true;
														actionHolding[index] = true;
												}
												if(keyinput.keystate is KeyState.released){
														actionReleased[index] = true;
														actionHolding[index] = false;
												}
												
										}
								}
						}
						foreach(index, axisKeyMatches; axisBindings){
								foreach(axisKeyMatch; axisKeyMatches){
										if(axisKeyMatch[0].key is keyinput.key){
												if(axisKeyMatch[0].keymod is keyinput.modifier){
														if(keyinput.keystate is KeyState.pressed){
																axisDown[index] += axisKeyMatch[1];
														}
												}
												if(keyinput.keystate is KeyState.released && axisDown[index] !is 0){
														axisDown[index] += -axisKeyMatch[1];
												}
										}
								}
						}

				}
		}

		struct KeyMatch{
				Key key;
				uint keymod;
		}
		void action(string name, KeyMods...)(Key key, KeyMods keymods){
				import std.meta: staticIndexOf;
				enum index = staticIndexOf!(name, Action.names);
				static if(keymods.length > 0){
						actionBindings[index].insert(KeyMatch(key, varOr(keymods)));
				}
				else{
						actionBindings[index].insert(KeyMatch(key, 0));
				}
		}

		bool getAction(KeyState state, string name)(){
				import std.meta;
				import std.algorithm.searching;
				enum index = staticIndexOf!(name, Action.names);
				static if(state is KeyState.pressed){
						return actionPressed[index];
				}
				else if(state is KeyState.released){
						return actionReleased[index];
				}
				else{
						return actionHolding[index];
				}
		}

		void axis(string name, KeyMods...)(int value, Key key, KeyMods keymods){
				import std.meta;
				enum filterAxisState(string name, alias axisState) = axisState.name is name;
				enum filterByName(alias axisState) = filterAxisState!(name, axisState);
				alias r = Filter!(filterByName, Axis.names);
				static assert(r.length is 1, "Needs to be 1");
				enum index = staticIndexOf!(r[0], Axis.names);
				static if(keymods.length > 0){
						axisBindings[index].insert(tuple(KeyMatch(key, varOr(keymods)), value));
				}
				else{
						axisBindings[index].insert(tuple(KeyMatch(key, 0), value));
				}
		}
		float getAxis(string name)(){
				import std.range;
				import std.meta;
				import std.algorithm.iteration;
				import std.algorithm.comparison;
				enum filterAxisState(string name, alias axisState) = axisState.name is name;
				enum filterByName(alias axisState) = filterAxisState!(name, axisState);
				alias r = Filter!(filterByName, Axis.names);
				static assert(r.length is 1, "Needs to be 1");
				enum index = staticIndexOf!(r[0], Axis.names);
				return axisDown[index];
		}
}

enum KeyState{
		released,
		pressed,
		holding
}

enum MouseKey{
		left,
		middle,
		right,
		x1,
		x2
}

enum KeyMod{
		none   = KMOD_NONE,
		lshift = KMOD_LSHIFT,
		rshift = KMOD_RSHIFT,
		lctrl  = KMOD_LCTRL,
		rctrl  = KMOD_RCTRL,
		lalt,
		ralt,
		lgui,
		rgui,
		num,
		caps,
		mode,
		ctrl,
		shift,
		alt,
		gui,
		reserved
}

enum Key{
		unknown,
		backspace,
		tab,
		ret,
		escape,
		space,
		exclaim,
		quotedbl,
		hash,
		dollar,
		percent,
		ampersand,
		quote,
		leftparen,
		rightparen,
		asterisk,
		plus,
		comma,
		minus,
		period,
		slash,
		num0,
		num1,
		num2,
		num3,
		num4,
		num5,
		num6,
		num7,
		num8,
		num9,
		colon,
		semicolon,
		less,
		equals,
		greater,
		question,
		at,
		leftbracket,
		backslash,
		rightbracket,
		caret,
		underscore,
		backquote,
		a,
		b,
		c,
		d,
		e,
		f,
		g,
		h,
		i,
		j,
		k,
		l,
		m,
		n,
		o,
		p,
		q,
		r,
		s,
		t,
		u,
		v,
		w,
		x,
		y,
		z,
		del,
		capslock,
		f1,
		f2,
		f3,
		f4,
		f5,
		f6,
		f7,
		f8,
		f9,
		f10,
		f11,
		f12,
		printscreen,
		scrolllock,
		pause,
		insert,
		home,
		pageup,
		end,
		pagedown,
		right,
		left,
		down,
		up,
		numlockclear,
		kpDivide,
		kpMultiply,
		kpMinus,
		kpPlus,
		kpEnter,
		kp1,
		kp2,
		kp3,
		kp4,
		kp5,
		kp6,
		kp7,
		kp8,
		kp9,
		kp0,
		kpPeriod,
		application,
		power,
		kpEquals,
		f13,
		f14,
		f15,
		f16,
		f17,
		f18,
		f19,
		f20,
		f21,
		f22,
		f23,
		f24,
		execute,
		help,
		menu,
		select,
		stop,
		again,
		undo,
		cut,
		copy,
		paste,
		find,
		mute,
		volumeup,
		volumedown,
		kpComma,
		kpEqualsas400,
		alterase,
		sysreq,
		cancel,
		clear,
		prior,
		return2,
		separator,
		keyOut,
		oper,
		clearagain,
		crsel,
		exsel,
		kp00,
		kp000,
		thousandsseparator,
		decimalseparator,
		currencyunit,
		currencysubunit,
		kpLeftparen,
		kpRightparen,
		kpLeftbrace,
		kpRightbrace,
		kpTab,
		kpBackspace,
		kpA,
		kpB,
		kpC,
		kpD,
		kpE,
		kpF,
		kpXor,
		kpPower,
		kpPercent,
		kpLess,
		kpGreater,
		kpAmpersand,
		kpDblampersand,
		kpVerticalbar,
		kpDblverticalbar,
		kpColon,
		kpHash,
		kpSpace,
		kpAt,
		kpExclam,
		kpMemstore,
		kpMemrecall,
		kpMemclear,
		kpMemadd,
		kpMemsubtract,
		kpMemmultiply,
		kpMemdivide,
		kpPlusminus,
		kpClear,
		kpClearentry,
		kpBinary,
		kpOctal,
		kpDecimal,
		kpHexadecimal,
		lctrl,
		lshift,
		lalt,
		lgui,
		rctrl,
		rshift,
		ralt,
		rgui,
		mode,
		audionext,
		audioprev,
		audiostop,
		audioplay,
		audiomute,
		mediaselect,
		www,
		mail,
		calculator,
		computer,
		acSearch,
		acHome,
		acBack,
		acForward,
		acStop,
		acRefresh,
		acBookmarks,
		brightnessdown,
		brightnessup,
		displayswitch,
		kbdillumtoggle,
		kbdillumdown,
		kbdillumup,
		eject,
		sleep
}

enum int[236] keycodes = [
		0,
		8,
		9,
		13,
		27,
		32,
		33,
		34,
		35,
		36,
		37,
		38,
		39,
		40,
		41,
		42,
		43,
		44,
		45,
		46,
		47,
		48,
		49,
		50,
		51,
		52,
		53,
		54,
		55,
		56,
		57,
		58,
		59,
		60,
		61,
		62,
		63,
		64,
		91,
		92,
		93,
		94,
		95,
		96,
		97,
		98,
		99,
		100,
		101,
		102,
		103,
		104,
		105,
		106,
		107,
		108,
		109,
		110,
		111,
		112,
		113,
		114,
		115,
		116,
		117,
		118,
		119,
		120,
		121,
		122,
		127,
		1073741881,
		1073741882,
		1073741883,
		1073741884,
		1073741885,
		1073741886,
		1073741887,
		1073741888,
		1073741889,
		1073741890,
		1073741891,
		1073741892,
		1073741893,
		1073741894,
		1073741895,
		1073741896,
		1073741897,
		1073741898,
		1073741899,
		1073741901,
		1073741902,
		1073741903,
		1073741904,
		1073741905,
		1073741906,
		1073741907,
		1073741908,
		1073741909,
		1073741910,
		1073741911,
		1073741912,
		1073741913,
		1073741914,
		1073741915,
		1073741916,
		1073741917,
		1073741918,
		1073741919,
		1073741920,
		1073741921,
		1073741922,
		1073741923,
		1073741925,
		1073741926,
		1073741927,
		1073741928,
		1073741929,
		1073741930,
		1073741931,
		1073741932,
		1073741933,
		1073741934,
		1073741935,
		1073741936,
		1073741937,
		1073741938,
		1073741939,
		1073741940,
		1073741941,
		1073741942,
		1073741943,
		1073741944,
		1073741945,
		1073741946,
		1073741947,
		1073741948,
		1073741949,
		1073741950,
		1073741951,
		1073741952,
		1073741953,
		1073741957,
		1073741958,
		1073741977,
		1073741978,
		1073741979,
		1073741980,
		1073741981,
		1073741982,
		1073741983,
		1073741984,
		1073741985,
		1073741986,
		1073741987,
		1073741988,
		1073742000,
		1073742001,
		1073742002,
		1073742003,
		1073742004,
		1073742005,
		1073742006,
		1073742007,
		1073742008,
		1073742009,
		1073742010,
		1073742011,
		1073742012,
		1073742013,
		1073742014,
		1073742015,
		1073742016,
		1073742017,
		1073742018,
		1073742019,
		1073742020,
		1073742021,
		1073742022,
		1073742023,
		1073742024,
		1073742025,
		1073742026,
		1073742027,
		1073742028,
		1073742029,
		1073742030,
		1073742031,
		1073742032,
		1073742033,
		1073742034,
		1073742035,
		1073742036,
		1073742037,
		1073742038,
		1073742039,
		1073742040,
		1073742041,
		1073742042,
		1073742043,
		1073742044,
		1073742045,
		1073742048,
		1073742049,
		1073742050,
		1073742051,
		1073742052,
		1073742053,
		1073742054,
		1073742055,
		1073742081,
		1073742082,
		1073742083,
		1073742084,
		1073742085,
		1073742086,
		1073742087,
		1073742088,
		1073742089,
		1073742090,
		1073742091,
		1073742092,
		1073742093,
		1073742094,
		1073742095,
		1073742096,
		1073742097,
		1073742098,
		1073742099,
		1073742100,
		1073742101,
		1073742102,
		1073742103,
		1073742104,
		1073742105,
		1073742106
];
