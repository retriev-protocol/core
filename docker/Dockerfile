FROM ubuntu:20.04 

# INSTALL BASIC DEPENDENCIES
RUN apt-get -qq update
RUN apt-get install -y \
  libssl-dev \
  ca-certificates \
  fuse \
  curl \
  wget

# INSTALL NODEJS
RUN curl -q https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs
RUN npm install -g npm
RUN npm install -g yarn

# INSTALL IPFS
RUN wget https://github.com/ipfs/kubo/releases/download/v0.28.0/kubo_v0.28.0_linux-386.tar.gz
RUN tar -xvzf kubo_v0.28.0_linux-386.tar.gz
RUN bash kubo/install.sh
RUN rm -rf kubo
RUN rm kubo_v0.28.0_linux-386.tar.gz

#INIT IPFS
RUN mkdir /data
WORKDIR /data

VOLUME  ["/data"]

EXPOSE 4001
EXPOSE 4001/udp
EXPOSE 5001
EXPOSE 8080
EXPOSE 8081
EXPOSE 9000
EXPOSE 8000

CMD tail -f /dev/null