mkdir -p artifacts

PACKAGE_VERSION=`head -1 ubuntu/debian/changelog | cut -f 2 -d "(" | cut -f 1 -d "~"`
NODE_VERSION=`echo ${PACKAGE_VERSION} | cut -f 1 -d "-"`

if [ ! -r dist/node_${NODE_VERSION}.orig.tar.gz ]; then
    wget https://github.com/nodejs/node/archive/refs/tags/v${NODE_VERSION}.tar.gz \
        -O dist/node_${NODE_VERSION}.orig.tar.gz
    git add dist/node_${NODE_VERSION}.orig.tar.gz
    tar -zxvf dist/node_${NODE_VERSION}.orig.tar.gz
    cd node-${NODE_VERSION}
    for SUB in doc clang-format lint-md; do
        ( cd tools/${SUB} && npm ci )
        mv tools/${SUB}/node_modules tools-${SUB}-node-modules
        tar -C tools-${SUB}-node-modules \
            -Jcvf ../dist/node_${NODE_VERSION}.orig-tools-${SUB}-node-modules.tar.xz .
    done
fi

if [ ! -r dist/node_${NODE_VERSION}.orig-node-addon-api.tar.xz ]; then
    mkdir -p node-addon-api
    for FILE in napi.h napi-inl.h napi-inl.deprecated.h; do
        wget https://raw.githubusercontent.com/nodejs/node-addon-api/v${NAPI_VERSION}/${FILE} \
            -O node-addon-api/${FILE}
    done
    tar -C node-addon-api -Jcvf dist/node_${NODE_VERSION}.orig-node-addon-api.tar.xz .
fi

for RELEASE in bionic focal jammy; do
    docker build --build-arg RELEASE=${RELEASE} \
        --build-arg NODE_VERSION=${NODE_VERSION} \
        -t mmomtchev/libnode-ubuntu-${RELEASE}:latest .

    docker run --network none \
        --env SRC_ONLY=1 \
        -v `ccache --get-config=cache_dir`:/ccache --env CCACHE_DIR=/ccache \
        -v `pwd`/artifacts:/out \
        -v ${HOME}/.gnupg:/root/.gnupg \
        mmomtchev/libnode-ubuntu-${RELEASE}:latest

    (
        cd artifacts/source
        dput --force ppa:mmomtchev/libnode node_${PACKAGE_VERSION}~${RELEASE}_source.changes
    )
done
