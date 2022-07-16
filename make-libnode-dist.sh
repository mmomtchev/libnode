#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-16.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ ! -r node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz
    tar -C node-16.x -zxvf node-16.x/dist/node_${NODE_VERSION}.orig.tar.gz
    (
        cd node-16.x/node-${NODE_VERSION}
        for SUB in doc clang-format lint-md; do
            ( cd tools/${SUB} && npm ci )
            mv tools/${SUB}/node_modules tools-${SUB}-node-modules
            tar -C tools-${SUB}-node-modules \
                -Jcvf ../dist/node_${NODE_VERSION}.orig-tools-${SUB}-node-modules.tar.xz .
        done
    )
    tar -C examples \
        -zcvf node-16.x/dist/node_${NODE_VERSION}.orig-examples.tar.gz \
        --exclude-from examples/.gitignore .
fi
