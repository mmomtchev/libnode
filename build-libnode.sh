#!/bin/bash

set -ex
mkdir -p artifacts

if [ -z "${BRANCH}" ]; then
	BRANCH=16
fi
if [ "${BRANCH}" == "16" ]; then
    PPA="ppa:mmomtchev/libnode"
else
    PPA="ppa:mmomtchev/libnode-${BRANCH}.x"
fi
PACKAGE_VERSION=`head -1 node-${BRANCH}.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ -n "${CACHE}" ]; then
    ARG_CACHE="--build-arg CACHE=1"
fi

if [ -z "${RELEASES}" ]; then
    RELEASES="bionic focal jammy"
fi
for RELEASE in ${RELEASES}; do
    docker build --build-arg RELEASE=${RELEASE} \
        --build-arg NODE_VERSION=${NODE_VERSION} \
        ${ARG_CACHE} \
        -t mmomtchev/libnode-ubuntu-${RELEASE}:latest node-${BRANCH}.x

    docker run --network none \
        --env SRC_ONLY=${SRC_ONLY} \
        --env BIN_ONLY=${BIN_ONLY} \
        -v `ccache --get-config=cache_dir`:/ccache --env CCACHE_DIR=/ccache \
        -v `pwd`/artifacts:/out \
        -v ${HOME}/.gnupg:/root/.gnupg \
        mmomtchev/libnode-ubuntu-${RELEASE}:latest

    (
        cd artifacts/source
        if [ -n "${PUBLISH}" ]; then
            dput --force ${PPA} node_${PACKAGE_VERSION}~${RELEASE}_source.changes
        fi
    )
done
