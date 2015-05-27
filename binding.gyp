{
	"targets": [
		{
			"target_name": "xcorr",
			"sources": [ "lib/xcorr.cc" ],
			"link_settings": {
				"libraries": [ "-L/usr/src/app/parallella-fft-xcorr", "-lfft-demo-coprthr"]
			}
		},
		{
			"target_name": "thermald",
			"sources": [ "lib/thermald.cc" ],
			"include_dirs": [ "$(EPIPHANY_HOME)/tools/host/include" ]
			"link_settings": {
				"libraries": [ "-L$(EPIPHANY_HOME)/tools/host/lib", "-lm", "-le-hal"]
			}
		}
	]
}
