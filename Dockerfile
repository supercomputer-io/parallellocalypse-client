FROM resin/armv7hf-node:0.10.38

RUN apt-get update \
  && apt-get install -y
    bison \
    curl \
    flex \
    freebsd-glue \
    git \
    htop \
    libconfig++-dev \
    libevent-dev \
    libjpeg-dev \
    nano \
    python \
    build-essential \
    wget
  && rm -rf /var/lib/apt/lists/*

ENV EPIPHANY_HOME /opt/adapteva/esdk
ENV EPIPHANY_VERSION  2015.1_linux_armv7l-20150523
RUN mkdir -p $EPIPHANY_HOME \
    && curl -sL http://ftp.parallella.org/esdk/beta/esdk.$EPIPHANY_VERSION.tar.gz \
    | tar xz -C /opt/adapteva/esdk --strip-components=1


# Enable default setup from webterminal
RUN sed -i 's/\/bin\/sh/\/bin\/bash/g' /opt/adapteva/esdk/setup.sh \
	&& echo "source /opt/adapteva/esdk/setup.sh" >> ~/.bashrc

RUN mkdir -p /app

# Build libelf 0.8.13
RUN cd /app && wget http://www.mr511.de/software/libelf-0.8.13.tar.gz \
	&& tar -xf libelf-0.8.13.tar.gz \
	&& cd libelf-0.8.13 && ./configure && make && make install

# Build COPRTHR
RUN bash -c "source /opt/adapteva/esdk/setup.sh && cd /app \
	&& git clone https://github.com/olajep/coprthr.git \
	&& cd /app/coprthr && git checkout parallellocalypse \
	&& ./configure --enable-epiphany \
	&& make && make install"

# Add COPRTHR MPI
RUN bash -c "source /opt/adapteva/esdk/setup.sh \
	&& cd /app \
	&& wget http://www.browndeertechnology.com/code/bdt-libcoprthr_mpi-preview.tgz \
	&& tar -xf bdt-libcoprthr_mpi-preview.tgz \
	&& cd /app/libcoprthr_mpi && ./install.sh"

# Clone the FFT correlation repo
RUN cd /app \
	&& git clone https://github.com/olajep/parallella-fft-xcorr \
	&& cd /app/parallella-fft-xcorr && git checkout c2bee839535bcff868cdeb7c1c5f735a60d02f44

ADD . /app

# Run this on startup.
CMD bash /app/run.sh
