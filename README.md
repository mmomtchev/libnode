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

The packages have been developed and are maintained as part of GSoC 2022 by the Open Source Geospatial Foundation and are copyright by Google and distributed under MIT License.
