#include <node.h>
#include <node_buffer.h>
#include <math.h>
#include <cstdlib>
#include <cstdio>
#include <ctime>
#include <limits>

using namespace v8;

// TO-DO: implement actual correlation
/*
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
*/

// The real function from Ola's library
bool calculateXCorr(uint8_t *jpeg1, size_t jpeg1_size,
		    uint8_t *jpeg2, size_t jpeg2_size,
		    float *corr);

void xcorr(const FunctionCallbackInfo<Value>& args) {
	Isolate* isolate = Isolate::GetCurrent();
	HandleScope scope(isolate);

	if (args.Length() < 3) {
		isolate->ThrowException(Exception::TypeError(
			String::NewFromUtf8(isolate, "Wrong number of arguments")));
		return;
	}

	Local<Object> bufferObj1 = args[0]->ToObject();
	unsigned char* image1 = (unsigned char *) node::Buffer::Data(bufferObj1);

	Local<Object> bufferObj2 = args[1]->ToObject();
	unsigned char* image2 = (unsigned char *) node::Buffer::Data(bufferObj2);

	size_t n1 = node::Buffer::Length(bufferObj1);
	size_t n2 = node::Buffer::Length(bufferObj2);
	//double xcorrValue = calculateXCorr(image1, image2, n);

	float xcorrValue;

	if(calculateXCorr(image1, n1, image2, n2, &xcorrValue))
		args.GetReturnValue().Set(Number::New(isolate, xcorrValue));
	
		Local<Function> cb = Local<Function>::Cast(args[2]);
		const unsigned argc = 1;
		Local<Value> argv[argc] = { Number::New(isolate, xcorrValue) };
		cb->Call(isolate->GetCurrentContext()->Global(), argc, argv);
	else
		isolate->ThrowException(Exception::TypeError(
			String::NewFromUtf8(isolate, "Correlation failed")));
		return;
}

void init(Handle<Object> exports, Handle<Object> module) {
	srand(time(NULL));
	NODE_SET_METHOD(module, "exports", xcorr);
}

NODE_MODULE(xcorr, init)
