FROM resin/armv7hf-node:0.10.38

RUN apt-get update \
  && apt-get install -y \
    bison \
    flex \
    freebsd-glue \
    libconfig++-dev \
  && rm -rf /var/lib/apt/lists/*

# Install epiphany SDK
ENV EPIPHANY_HOME /opt/adapteva/esdk
ENV ESDK_VERSION 2014.11.20150522

RUN mkdir -p $EPIPHANY_HOME \
    && curl -sL http://ftp.parallella.org/esdk/beta/esdk.$ESDK_VERSION_linux_armv7l.tar.gz | tar xz -C $EPIPHANY_HOME --strip-components=1

# Build libelf
ENV LIBELF_VERSION 0.8.13

RUN mkdir -p /usr/src/libelf \
    && curl -sL http://www.mr511.de/software/libelf-$LIBELF_VERSION.tar.gz | tar xz -C /usr/src/libelf --strip-components=1 \
    && cd /usr/src/libelf \
    && ./configure \
    && make \
    && make install \
    && rm -rf /usr/src/libelf

# Build libcoprthr
ENV LIBCOPRTHR_VERSION parallellocalypse

RUN . /opt/adapteva/esdk/setup.sh \
    && mkdir -p /usr/src/libcoprthr \
    && curl -sL https://github.com/olajep/coprthr/archive/$LIBCOPRTHR_VERSION.tar.gz | tar xz -C /usr/src/libcoprthr --strip-components=1 \
    && cd /usr/src/libcoprthr \
    && ./configure --enable-epiphany \
    && make \
    && make install \
    && rm -rf /usr/src/libcoprthr

# Enable default setup from webterminal
RUN sed -i 's/\/bin\/sh/\/bin\/bash/g' /opt/adapteva/esdk/setup.sh && echo "source /opt/adapteva/esdk/setup.sh" >> ~/.bashrc

RUN mkdir -p /app

# Install libcoprthr_mpi
ENV LIBCOPTHR_MPI_VERSION preview

RUN . /opt/adapteva/esdk/setup.sh \
    && mkdir -p /usr/src/libcoprthr-mpi \
    && curl -sL http://www.browndeertechnology.com/code/bdt-libcoprthr_mpi-$LIBCOPTHR_MPI_VERSION.tgz | tar xz -C /usr/src/libcoprthr-mpi --strip-components=1 \
    && cd /usr/src/libcoprthr-mpi \
    && ./install.sh \
    && rm -rf /usr/src/libcoprthr_mpi


# Clone the FFT correlation repo
RUN cd /app && git clone https://github.com/olajep/parallella-fft-xcorr \
	&& cd /app/parallella-fft-xcorr && git checkout c2bee839535bcff868cdeb7c1c5f735a60d02f44

ADD . /app

# Run this on startup.
CMD bash /app/run.sh
