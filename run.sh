
set -e

source /opt/adapteva/esdk/setup.sh

if [ ! -f /app/installed.txt ]; then
	echo "Building FFT correlation"
	cd /app/parallella-fft-xcorr && PATH=/usr/local/browndeer/bin:$PATH LD_LIBRARY_PATH=/usr/local/browndeer/lib:$LD_LIBRARY_PATH make

	echo "Installing app"
	cd /app && npm install --unsafe-perm

	touch /app/installed.txt
fi

cd /app && npm start
