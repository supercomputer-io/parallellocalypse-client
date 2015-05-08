#include <node.h>
#include <node_buffer.h>
#include <math.h>

using namespace v8;

// TO-DO: implement actual correlation
double calculateXCorr(char * image1, char * image2, size_t n) {
	return 0.53;
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
	NODE_SET_METHOD(module, "exports", xcorr);
}

NODE_MODULE(xcorr, init)
