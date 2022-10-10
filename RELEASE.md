# Upgrading to a new Node.js version

1. Checkout the `napi-libnode-v18.x` branch of https://github.com/mmomtchev/node and rebase it on top of the latest tag (ie `v18.10.0`)

2. `export BRANCH=18`

3. `bash make-libnode-dist.sh`
    This will create the `-orig` tarballs

4. `bash extract-libnode-dir.sh`
    This will create the debian source directory, reapply and refresh the patches (patches will be modified after this step)

5. `bash make-patch.sh ../node-napi-libnode-v18.x` (directory with the `napi-libnode-v18.x` checkout)
    This will create a new `libnode` patch with all the eventual modifications from the rebase in step 1

6. `BIN_ONLY=1 bash build-libnode.sh`
    This will simply test building the new packages

7. `PUBLISH=1 SRC_ONLY=1 bash build-libnode.sh`
    This will publish the new packages
