#!/bin/bash

set -ex
mkdir -p artifacts

if [ -z "${BRANCH}" ]; then
	BRANCH=16
fi
PACKAGE_VERSION=`head -1 node-${BRANCH}.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`
mkdir -p node-${BRANCH}.x/dist/

if [ ! -r node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig.tar.gz
    tar -C node-${BRANCH}.x/dist -zxvf node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig.tar.gz
    (
        cd node-${BRANCH}.x/dist/node-${NODE_VERSION}
        for SUB in doc clang-format lint-md; do
            ( cd tools/${SUB} && npm ci )
            mv tools/${SUB}/node_modules tools-${SUB}-node-modules
            tar -C tools-${SUB}-node-modules \
                -Jcvf ../node_${NODE_VERSION}.orig-tools-${SUB}-node-modules.tar.xz .
        done
    )
    tar -C examples \
        -zcvf node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig-examples.tar.gz \
        --exclude-from examples/.gitignore .
    rm -rf node-${BRANCH}.x/dist/node-${NODE_VERSION}
fi
