FROM ubuntu:bionic

ARG NODE_VERSION=16.15.1

RUN set -ex && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install debhelper build-essential python3 g++-8 make python3-pip wget

RUN wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz && \
    mv v${NODE_VERSION}.tar.gz node_${NODE_VERSION}.orig.tar.gz && \
    tar -zxvf node_${NODE_VERSION}.orig.tar.gz

COPY debian /node-${NODE_VERSION}/debian

RUN cd /node-${NODE_VERSION} && debuild -us -uc
