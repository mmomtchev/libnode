ARG RELEASE=bionic
FROM ubuntu:${RELEASE}

ARG NODE_VERSION=16.15.1
ARG NAPI_VERSION=5.0.0
ENV NODE_VERSION=${NODE_VERSION}
ENV NAPI_VERSION=${NAPI_VERSION}

ARG OPERATION="-us -uc"
ARG FAST
ENV DEB_OPERATION=${OPERATION}
ENV DEB_BUILD_OPTIONS=${FAST:+nocheck}
ENV CCACHE_LOGFILE=/tmp/cache.debug
ENV DEB_BUILD_ARGS=${FAST:+"--preserve-envvar=CCACHE_DIR --preserve-envvar=CCACHE_LOGFILE --prepend-path=/usr/lib/ccache"}

RUN set -ex && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install lsb-release && \
    if [ `lsb_release -cs` = 'bionic' ]; then \
        GCC=gcc-8 GCXX=g++-8; \
    else \
        GCC=gcc GCXX=g++; \
    fi && \
    echo ${GCC} > /gcc && \
    echo ${GCXX} > /gcxx && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install devscripts debhelper build-essential quilt \
        ccache \
        python3 ${GCC} ${GCXX} make python3-pip wget

RUN wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O node_${NODE_VERSION}.orig.tar.gz && \
    tar -zxvf node_${NODE_VERSION}.orig.tar.gz

COPY debian /node-${NODE_VERSION}/debian

WORKDIR /node-${NODE_VERSION} 

ENTRYPOINT CC=`cat /gcc` CXX=`cat /gcxx` exec debuild ${DEB_BUILD_ARGS} \
    --preserve-envvar=CC --preserve-envvar=CXX  \
    --preserve-envvar=NAPI_VERSION --preserve-envvar=NODE_VERSION \
    ${DEB_OPERATION}
