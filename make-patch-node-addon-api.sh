#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-addon-api/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

TARGET=node-addon-api/dist
SRC=$1 # The path the git checkout of https://github.com/mmomtchev/node-addon-api

(
	cd ${SRC}
	git diff -r v${NODE_VERSION} > ~/src/repatch-napi-embedding
)

(
	set -ex
	export QUILT_PATCHES=debian/patches
	cd ${TARGET}/node-addon-api-${NODE_VERSION}/
	quilt pop -a || true
	quilt delete napi-embedding.diff || true
	quilt new napi-embedding.diff
	lsdiff --strip 1 < ~/src/repatch-napi-embedding | xargs -t quilt add || true
	patch -p1 < ~/src/repatch-napi-embedding
	quilt refresh
	cp  debian/patches/series debian/patches/napi-embedding.diff ~/src/libnode/node-addon-api/ubuntu/debian/patches
)
