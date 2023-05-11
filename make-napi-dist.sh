#!/bin/bash

PACKAGE_VERSION=`head -1 node-addon-api/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ ! -r node-addon-api/dist/node-addon-api_${NODE_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node-addon-api/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O node-addon-api/dist/node-addon-api_${NODE_VERSION}.orig.tar.gz
fi
