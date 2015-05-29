#!/bin/bash

set -o errexit

source /opt/adapteva/esdk/setup.sh

if [ ! -f /usr/src/app/installed.txt ]; then
	echo "Building FFT correlation"
	cd /usr/src/app/parallella-fft-xcorr && make clean && PATH=/usr/local/browndeer/bin:$PATH LD_LIBRARY_PATH=/usr/local/browndeer/lib:$LD_LIBRARY_PATH make IMPL=coprthr
	install -m 644 /usr/src/app/parallella-fft-xcorr/libfft-demo-coprthr.so /usr/lib/
	ldconfig /usr/lib /usr/local/browndeer/lib

	cp /usr/src/app/parallella-fft-xcorr/device.cbin.3.e32 /usr/src/app/
	echo "Installing app"
	#cd /usr/src/app && npm install --unsafe-perm
	cd /usr/src/app && ./node_modules/.bin/node-gyp configure build

	touch /usr/src/app/installed.txt
fi

cd /usr/src/app && npm start

echo "Application exited"

sleep 99999999
