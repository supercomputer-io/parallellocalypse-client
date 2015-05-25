{
	"targets": [
		{
			"target_name": "xcorr",
			"sources": [ "lib/xcorr.cc" ],
			"link_settings": {
				"libraries": [ "-L/app/parallella-fft-xcorr", "-lfft-demo-coprthr"]
			}
		}
	]
}
