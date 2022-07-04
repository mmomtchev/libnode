# Current libnode packages for Ubuntu and Debian

This repository contains the scripts used to generate the Ubuntu and Debian packages of `libnode`

Ubuntu PPA: https://launchpad.net/~mmomtchev/+archive/ubuntu/libnode

Unlike the distributions built-in packages, these packages:
* Are similar to the [NodeSource binary distributions](https://github.com/nodesource/distributions)
* Use self-contained packages that include all Node.js dependencies in the same executable - as very few people use both `libnode` and `libuv` or `v8` independently in the same project bundling these separately has no real benefit
* Provide current versions even for old distributions
* Include [PR#43542](https://github.com/nodejs/node/pull/43542) allowing to embed the Node.js entirely through the binary stable Node-API from both C and C++. This PR might or might not get merged (it is currently under discussions)
* Are not supported on all hardware platforms
* Are not restrained by Debian dogma (some of the included dependencies are not fully GPL-compatible - but it is still qualifies as free software)
* `node-addon-api@5.0.0` is included in `libnode-dev`

The packages have been developed as part of GSoC 2022 on a project sponsored by the Open Source Geospatial Foundation and are copyright by Google and distributed under MIT License.

I am maintaining them as a courtesy to the open source community.

# Supported Platforms

Node.js 16.x and (_in progress_) Node.js 18.x on

* Ubuntu 18.04 (**Bionic**)
* Ubuntu 20.04 (**Focal**)
* Ubuntu 22.04 (**Jammy**)
* (_in progress_) Debian 10 (**Buster**)
* (_in progress_) Debian 11 (**Bullseye**)

# Using from C/C++

This version of `libnode` can be used from both C and C++ with a simple Node-API interface:

