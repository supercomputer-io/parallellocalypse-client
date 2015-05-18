FROM resin/armv7hf-debian:jessie

RUN apt-get update \
	&& apt-get install -y build-essential axel wget htop nano libjpeg-dev libconfig++-dev libevent-dev git freebsd-glue\
	&& apt-get clean \
        && apt-get autoremove -qqy 

RUN mkdir -p /opt/adapteva && cd /opt/adapteva \
	&& axel -n 10 http://ftp.parallella.org/esdk/esdk.2014.11_linux_armv7l.tar.gz && tar -xf esdk.2014.11_linux_armv7l.tar.gz && rm esdk.2014.11_linux_armv7l.tar.gz \
	&& ln -sTf /opt/adapteva/esdk.2014.11 /opt/adapteva/esdk

ENV EPIPHANY_HOME /opt/adapteva/esdk

# Enable default setup from webterminal
RUN sed -i 's/\/bin\/sh/\/bin\/bash/g' /opt/adapteva/esdk/setup.sh && echo "source /opt/adapteva/esdk/setup.sh" >> ~/.bashrc

RUN mkdir -p /app
ADD . /app
RUN cd /app && wget http://www.browndeertechnology.com/code/bdt-libcoprthr_mpi-preview.tgz

# Fix the permissions of run.sh and build.sh for pushes from windows.
RUN chmod a+x /app/build.sh

RUN curl -sL https://deb.nodesource.com/setup | bash -
RUN apt-get install -y build-essential nodejs

# Source the setup and build the dependencies.
RUN bash -c "source /opt/adapteva/esdk/setup.sh && ./app/build.sh"

# Run this on startup.
CMD bash -c "source /opt/adapteva/esdk/setup.sh && cd /app && npm start"
