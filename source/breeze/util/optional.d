module breeze.util.optional;

import breeze.util.algebraic;

struct None{}

struct Some(T){
	T value;
}

alias Option(T) = Algebraic!(Some!T, None);


Option!T some(T)(T value){
	return Option!T(Some!T(value));
}
Option!T none(T)(){
	return Option!T(None());
}

unittest{
	auto some = some(5);
}

