FROM resin/armv7hf-debian:jessie

RUN apt-get update \
	&& apt-get install -y axel wget htop nano libjpeg-dev libconfig++-dev\
	libevent-dev git freebsd-glue curl python bison flex\
	&& apt-get clean \
        && apt-get autoremove -qqy 

RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y build-essential nodejs

RUN mkdir -p /opt/adapteva && cd /opt/adapteva \
	&& axel -n 10 http://ftp.parallella.org/esdk/beta/esdk.2014.11.20150522_linux_armv7l.tar.gz && tar -xf esdk.2014.11.20150522_linux_armv7l.tar.gz && rm esdk.2014.11.20150522_linux_armv7l.tar.gz \
	&& ln -sTf /opt/adapteva/esdk.2014.11 /opt/adapteva/esdk

ENV EPIPHANY_HOME /opt/adapteva/esdk

# Enable default setup from webterminal
RUN sed -i 's/\/bin\/sh/\/bin\/bash/g' /opt/adapteva/esdk/setup.sh && echo "source /opt/adapteva/esdk/setup.sh" >> ~/.bashrc

RUN mkdir -p /app

# Build libelf 0.8.13
RUN cd /app && wget http://www.mr511.de/software/libelf-0.8.13.tar.gz \
	&& tar -xf libelf-0.8.13.tar.gz \
	&& cd libelf-0.8.13 && ./configure && make && make install

# Build COPRTHR
RUN bash -c "source /opt/adapteva/esdk/setup.sh && cd /app \
	&& git clone https://github.com/olajep/coprthr.git \
	&& cd /app/coprthr && git checkout parallellocalypse && ./configure --enable-epiphany \
	&& make && make install"

# Add COPRTHR MPI
RUN bash -c "source /opt/adapteva/esdk/setup.sh && cd /app && wget http://www.browndeertechnology.com/code/bdt-libcoprthr_mpi-preview.tgz \
	&& tar -xf bdt-libcoprthr_mpi-preview.tgz \
	&& cd /app/libcoprthr_mpi && ./install.sh"

# Clone the FFT correlation repo
RUN cd /app && git clone https://github.com/olajep/parallella-fft-xcorr \
	&& cd /app/parallella-fft-xcorr && git checkout c2bee839535bcff868cdeb7c1c5f735a60d02f44

ADD . /app

# Run this on startup.
CMD bash /app/run.sh
