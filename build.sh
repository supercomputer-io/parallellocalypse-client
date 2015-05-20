
set -e

# Install libelf
cd /app && wget http://www.mr511.de/software/libelf-0.8.13.tar.gz
tar -xf libelf-0.8.13.tar.gz
cd libelf-0.8.13 && ./configure && make && make install

# Install COPRTHR
cd /app
git clone https://github.com/olajep/coprthr.git
cd /app/coprthr && ./configure --enable-epiphany && make && make install

# Install libcoprthr_mpi
cd /app
tar -xf bdt-libcoprthr_mpi-preview.tgz
cd /app/libcoprthr_mpi && ./install.sh

# Install the fft correlation library
cd /app
git clone https://github.com/olajep/parallella-fft-xcorr
