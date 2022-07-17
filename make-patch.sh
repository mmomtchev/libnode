#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-16.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

TARGET=node-16.x/dist
SRC=$1 # The path the git checkout of https://github.com/mmomtchev/node

(
	cd ${SRC}
	git diff -r v${NODE_VERSION} > ~/src/repatch
)

(
	set -ex
	cd ${TARGET}/node-${NODE_VERSION}/
	quilt pop -a
	quilt push
	lsdiff --strip 1 < ~/src/repatch | xargs quilt add || true
	patch -p1 -R < debian/patches/napi-libnode.diff
	patch -p1 < ~/src/repatch
	quilt refresh
	cp debian/patches/napi-libnode.diff ~/src/libnode/node-16.x/ubuntu/debian/patches
)
