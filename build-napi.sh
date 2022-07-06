#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-addon-api/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NAPI_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ ! -r node-addon-api/dist/node-addon-api_${NAPI_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node-addon-api/archive/refs/tags/v${NAPI_VERSION}.tar.gz \
        -O node-addon-api/dist/node-addon-api_${NAPI_VERSION}.orig.tar.gz
fi

if [ -z "${RELEASES}" ]; then
    RELEASES=bionic focal jammy
fi
for RELEASE in ${RELEASES}; do
    rm -rf node-addon-api/ubuntu/${RELEASE}/node-addon-api_${NAPI_VERSION}
    mkdir -p node-addon-api/ubuntu/${RELEASE}
    tar -C node-addon-api/ubuntu/${RELEASE} \
        -zxvf node-addon-api/dist/node-addon-api_${NAPI_VERSION}.orig.tar.gz
    cp node-addon-api/dist/node-addon-api_${NAPI_VERSION}.orig.tar.gz \
        node-addon-api/ubuntu/${RELEASE}
    cp -a node-addon-api/ubuntu/debian \
        node-addon-api/ubuntu/${RELEASE}/node-addon-api-${NAPI_VERSION}
    (
        cd node-addon-api/ubuntu/${RELEASE}/node-addon-api-${NAPI_VERSION}

        sed -i s/UNIVERSAL/${RELEASE}/g debian/changelog
        sed -i s/_NAPI_VERSION_/${NAPI_VERSION}/g debian/rules

        debuild
        debuild -sa -S

        cd ..
        dput --force ppa:mmomtchev/libnode node-addon-api_${PACKAGE_VERSION}~${RELEASE}_source.changes
    )
done
