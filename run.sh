
set -e

source /opt/adapteva/esdk/setup.sh

if [ ! -f /app/installed.txt ]; then
	echo "Building FFT correlation"
	cd /app/parallella-fft-xcorr && PATH=/usr/local/browndeer/bin:$PATH LD_LIBRARY_PATH=/usr/local/browndeer/lib:$LD_LIBRARY_PATH make
	install -m 644 /app/parallella-fft-xcorr/libfft-demo.so /usr/local/lib/
	ldconfig -n /usr/local/lib

	ls -l /usr/local/lib

	echo "Installing app"
	cd /app && npm install --unsafe-perm

	touch /app/installed.txt
fi

cd /app && npm start
