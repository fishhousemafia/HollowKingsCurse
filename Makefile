default all:
	clang -shared -o ffi/libvector2.so -fPIC ffi/vector2.c
