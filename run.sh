
set -e

source /opt/adapteva/esdk/setup.sh

if [ ! -f /app/installed.txt ]; then
	echo "Building FFT correlation"
	cd /app/parallella-fft-xcorr && PATH=/usr/local/browndeer/bin:$PATH LD_LIBRARY_PATH=/usr/local/browndeer/lib:$LD_LIBRARY_PATH make
	install /app/parallella-fft-xcorr/libfft-demo.so /usr/local/lib
	ldconfig -n /usr/local/lib /usr/local/browndeer/lib
	echo "Installing app"
	cd /app && npm install --unsafe-perm

	touch /app/installed.txt
fi

cd /app && npm start
