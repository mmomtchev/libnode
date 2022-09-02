#!/bin/bash

set -ex
mkdir -p artifacts

if [ -z "${BRANCH}" ]; then
	BRANCH=16
fi
PACKAGE_VERSION=`head -1 node-${BRANCH}.x/ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`
TARGET=node-${BRANCH}.x/dist

if [ -d "${TARGET}/node-${NODE_VERSION}" ]; then
	echo "Will delete ${TARGET}/node-${NODE_VERSION}"
	read -p "Press enter to continue"
	rm -rf "${TARGET}/node-${NODE_VERSION}"
fi

tar -C ${TARGET} -zxvf node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig.tar.gz
for SUB in doc clang-format lint-md; do
	mkdir -p ${TARGET}/node-${NODE_VERSION}/tools-${SUB}-node-modules
	tar -C ${TARGET}/node-${NODE_VERSION}/tools-${SUB}-node-modules -Jxvf node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig-tools-${SUB}-node-modules.tar.xz
done
mkdir -p ${TARGET}/node-${NODE_VERSION}/examples 
tar -C ${TARGET}/node-${NODE_VERSION}/examples -zxvf node-${BRANCH}.x/dist/node_${NODE_VERSION}.orig-examples.tar.gz

cp -a node-${BRANCH}.x/ubuntu/debian ${TARGET}/node-${NODE_VERSION}
(
	cd ${TARGET}/node-${NODE_VERSION}
	export QUILT_PATCHES=debian/patches
	quilt push -a --refresh
)

cp ${TARGET}/node-${NODE_VERSION}/debian/patches/*.diff node-${BRANCH}.x/ubuntu/debian/patches

(
	cd ${TARGET}/node-${NODE_VERSION}
	RELEASE=`lsb_release -cs`

	sed -i s/UNIVERSAL/${RELEASE}/g debian/changelog
	sed -i s/_NODE_VERSION_/${NODE_VERSION}/g debian/rules
	sed -i s/_GCC_/gcc/g debian/rules
	sed -i s/_GCXX_/g\+\+/g debian/rules
	sed -i s/_GCXX_/g\+\+/g debian/control
)
