{
	"targets": [
		{
			"target_name": "xcorr",
			"sources": [ "lib/xcorr.cc" ],
			"include_dirs": ["/usr/src/app/parallella-fft-xcorr"],
			"link_settings": {
				"libraries": [ "-L/usr/src/app/parallella-fft-xcorr", "-lfft-demo-coprthr"]
			}
		}
	]
}
