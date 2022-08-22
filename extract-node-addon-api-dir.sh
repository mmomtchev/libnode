#!/bin/bash

set -ex
mkdir -p artifacts

PACKAGE_VERSION=`head -1 node-addon-api/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`
TARGET=node-addon-api/dist

tar -C ${TARGET} -zxvf node-addon-api/dist/node-addon-api_${NODE_VERSION}.orig.tar.gz

cp -a node-addon-api/ubuntu/debian ${TARGET}/node-addon-api-${NODE_VERSION}
(
	cd ${TARGET}/node-addon-api-${NODE_VERSION}
	export QUILT_PATCHES=debian/patches
	quilt push -a --refresh
)

cp ${TARGET}/node-addon-api-${NODE_VERSION}/debian/patches/*.diff node-addon-api/ubuntu/debian/patches

(
	cd ${TARGET}/node-addon-api-${NODE_VERSION}
	RELEASE=`lsb_release -cs`

	sed -i s/UNIVERSAL/${RELEASE}/g debian/changelog
	sed -i s/_NODE_VERSION_/${NODE_VERSION}/g debian/rules
	sed -i s/_GCC_/gcc/g debian/rules
	sed -i s/_GCXX_/g\+\+/g debian/rules
	sed -i s/_GCXX_/g\+\+/g debian/control
)
