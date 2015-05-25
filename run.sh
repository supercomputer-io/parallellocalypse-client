#!/bin/bash

set -o errexit

source /opt/adapteva/esdk/setup.sh

if [ ! -f /app/installed.txt ]; then
	echo "Building FFT correlation"
	cd /app/parallella-fft-xcorr && PATH=/usr/local/browndeer/bin:$PATH LD_LIBRARY_PATH=/usr/local/browndeer/lib:$LD_LIBRARY_PATH make IMPL=coprthr
	install -m 644 /app/parallella-fft-xcorr/libfft-demo-coprthr.so /usr/lib/
	ldconfig /usr/lib /usr/local/browndeer/lib

	cp /app/parallella-fft-xcorr/device.cbin.3.e32 /app/
	echo "Installing app"
	cd /app && npm install --unsafe-perm

	touch /app/installed.txt
fi

cd /app && npm start

echo "Application exited"

sleep 99999999
