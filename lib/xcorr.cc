#include <node.h>
#include <node_buffer.h>
#include <math.h>
#include <cstdlib>
#include <cstdio>
#include <ctime>
#include <limits>

using namespace v8;

// TO-DO: implement actual correlation
double calculateXCorr(char * image1, char * image2, size_t n) {
	
	double result = 0.0;

	for(size_t i = 0; i < (4 * n); i++) {
		for(size_t j = 0; j < (4 * n); j++) {
			result +=  ((double)*(image1+i+n*j))*((double)*(image2+i+n*j));
		}
	}

	result /= (4*n)^2;

	return result;
}

void xcorr(const FunctionCallbackInfo<Value>& args) {
	Isolate* isolate = Isolate::GetCurrent();
	HandleScope scope(isolate);

	if (args.Length() < 2) {
		isolate->ThrowException(Exception::TypeError(
			String::NewFromUtf8(isolate, "Wrong number of arguments")));
		return;
	}

	Local<Object> bufferObj1 = args[0]->ToObject();
	char* image1 = node::Buffer::Data(bufferObj1);

	Local<Object> bufferObj2 = args[1]->ToObject();
	char* image2 = node::Buffer::Data(bufferObj2);

	size_t n = sqrt(node::Buffer::Length(bufferObj1)/4);

	double xcorrValue = calculateXCorr(image1, image2, n);

	args.GetReturnValue().Set(Number::New(isolate, xcorrValue));
}

void init(Handle<Object> exports, Handle<Object> module) {
	srand(time(NULL));
	NODE_SET_METHOD(module, "exports", xcorr);
}

NODE_MODULE(xcorr, init)
