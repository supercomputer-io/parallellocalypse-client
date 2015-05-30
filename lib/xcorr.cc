#include <node.h>
#include <node_buffer.h>
#include <nan.h>
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

extern "C" {
	// The real function from Ola's library
	/*bool calculateXCorr(uint8_t *jpeg1, size_t jpeg1_size,
		    uint8_t *jpeg2, size_t jpeg2_size,
		    float *corr);*/
	#include <libfft-demo.h>
}


NAN_METHOD(xcorr) {
	NanScope();

	if (args.Length() < 3) {
		ThrowException(Exception::TypeError(
			NanNew<String>("Wrong number of arguments")));
		NanReturnUndefined();
	}

	Local<Object> bufferObj1 = args[0]->ToObject();
	unsigned char* image1 = (unsigned char *) node::Buffer::Data(bufferObj1);

	//Local<Object> bufferObj2 = args[1]->ToObject();
	//unsigned char* image2 = (unsigned char *) node::Buffer::Data(bufferObj2);

	size_t n1 = node::Buffer::Length(bufferObj1);
	
	//size_t n2 = node::Buffer::Length(bufferObj2);
	//double xcorrValue = calculateXCorr(image1, image2, n);


	
	struct jpeg_image image1s;
	image1s.data = image1;
	image1s.size = n1;

	Local<Array> imagesArray = Local<Array>::Cast(args[1]);
	size_t arrayLength = imagesArray->Length();

	struct jpeg_image images[arrayLength];

	for(size_t i = 0; i < arrayLength; i++) {
		Local<Object> bufObj = imagesArray->Get(i)->ToObject();
		images[i].data = (uint8_t *) node::Buffer::Data(bufObj);
		images[i].size = (size_t) node::Buffer::Length(bufObj);
	}

	float xcorrValue[arrayLength];

	if(calculateXCorr2(&image1s, images, (int) arrayLength, xcorrValue)) {
		Local<Function> cb = args[2].As<Function>();
		const unsigned argc = 1;
		Local<Value> argv[argc];
		Local<Array> results = NanNew<Array>(arrayLength);
		for(size_t i = 0; i < arrayLength; i++)
			results->Set(i, NanNew<Number>(xcorrValue[i]));
		argv[0] = results;
		cb->Call(Context::GetCurrent()->Global(), argc, argv);
	}
	else {
		ThrowException(Exception::TypeError(
			NanNew<String>("Correlation failed")));
	}
	
	NanReturnUndefined();
}

void Init(Handle<Object> exports, Handle<Object> module) {
	module->Set(NanNew<String>("exports"),
    	NanNew<FunctionTemplate>(xcorr)->GetFunction());
}
NODE_MODULE(xcorr, Init)
