ARG RELEASE=bionic
FROM ubuntu:${RELEASE}

ARG RELEASE
ARG NODE_VERSION=16.15.1
ARG NAPI_VERSION=5.0.0
ENV NODE_VERSION=${NODE_VERSION}
ENV NAPI_VERSION=${NAPI_VERSION}

ARG FAST
ENV DEB_BUILD_OPTIONS=${FAST:+nocheck}
ENV CCACHE_LOGFILE=/tmp/cache.debug
ENV CCACHE_ARGS=${FAST:+"--preserve-envvar=CCACHE_DIR --preserve-envvar=CCACHE_LOGFILE --prepend-path=/usr/lib/ccache"}

RUN set -ex && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install lsb-release && \
    if [ `lsb_release -cs` = 'bionic' ]; then \
        GCC=gcc-8 GCXX=g++-8; \
    else \
        GCC=gcc GCXX=g++; \
    fi && \
    mkdir -p /env && \
    echo ${GCC} > /env/gcc && \
    echo ${GCXX} > /env/gcxx && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install devscripts debhelper build-essential quilt \
        ccache wget \
        python3 ${GCC} ${GCXX} make python3-pip && \
    wget -O - https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

COPY dist/node_${NODE_VERSION}.orig* /

RUN set -ex && \
    tar -zxvf /node_${NODE_VERSION}.orig.tar.gz && \
    cd node-${NODE_VERSION} && \
    for SUB in /node_${NODE_VERSION}.orig-*.tar.xz; do \
        DIR=`echo ${SUB}  | cut -f 2- -d "-" | cut -f 1 -d "."` && \ 
        mkdir -p ${DIR} && \
        tar -C ${DIR} -Jxvf ${SUB}; \
    done && \
    mkdir -p examples && tar -C examples -zxvf /node_${NODE_VERSION}.orig-examples.tar.gz

COPY ubuntu/debian /node-${NODE_VERSION}/debian

RUN sed -i s/UNIVERSAL/${RELEASE}/g /node-${NODE_VERSION}/debian/changelog && \
    sed -i s/_NAPI_VERSION_/${NAPI_VERSION}/g /node-${NODE_VERSION}/debian/rules && \
    sed -i s/_NODE_VERSION_/${NODE_VERSION}/g /node-${NODE_VERSION}/debian/rules && \
    sed -i s/_GCC_/`cat /env/gcc`/g /node-${NODE_VERSION}/debian/rules && \
    sed -i s/_GCXX_/`cat /env/gcxx`/g /node-${NODE_VERSION}/debian/rules && \
    sed -i s/_GCXX_/`cat /env/gcxx`/g /node-${NODE_VERSION}/debian/control

WORKDIR /node-${NODE_VERSION} 

ENTRYPOINT exec /bin/bash -c \
    'set -ex && \
    env && \
    debuild -sa -S && \
    mkdir -p /out/source && \
    cp ../node*tar* ../*.changes ../*.dsc ../*.buildinfo /out/source && \
    if [ ! -n "${SRC_ONLY}" ]; then \
        debuild ${CCACHE_ARGS} && \
        mkdir -p /out/amd64 && \
        cp ../*.changes ../*.dsc ../*.debian.tar.xz ../*.buildinfo ../*.deb /out/amd64 && \
        cp ${CCACHE_LOGFILE} /out; \
    fi'
