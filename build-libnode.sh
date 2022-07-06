#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-16.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ ! -r node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz
    tar -zxvf node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz
    (
        cd node-16.x/node-${NODE_VERSION}
        for SUB in doc clang-format lint-md; do
            ( cd tools/${SUB} && npm ci )
            mv tools/${SUB}/node_modules tools-${SUB}-node-modules
            tar -C tools-${SUB}-node-modules \
                -Jcvf ../dist/node_${NODE_VERSION}.orig-tools-${SUB}-node-modules.tar.xz .
        done
    )
fi

if [ -z "${RELEASES}" ]; then
    RELEASES=bionic focal jammy
fi
for RELEASE in ${RELEASES}; do
    docker build --build-arg RELEASE=${RELEASE} \
        --build-arg NODE_VERSION=${NODE_VERSION} \
        -t mmomtchev/libnode-ubuntu-${RELEASE}:latest node-16.x

    docker run --network none \
        --env SRC_ONLY=${SRC_ONLY} \
        ${ARG_FAST}
        -v `ccache --get-config=cache_dir`:/ccache --env CCACHE_DIR=/ccache \
        -v `pwd`/artifacts:/out \
        -v ${HOME}/.gnupg:/root/.gnupg \
        mmomtchev/libnode-ubuntu-${RELEASE}:latest

    (
        cd artifacts/source
        dput --force ppa:mmomtchev/libnode node_${PACKAGE_VERSION}~${RELEASE}_source.changes
    )
done
