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

I am maintaining them as courtesy to the open source community.

# Supported Platforms

Node.js 16.x and (_in progress_) Node.js 18.x on

* Ubuntu 18.04 (**Bionic**)
* Ubuntu 20.04 (**Focal**)
* Ubuntu 22.04 (**Jammy**)
* (_in progress_) Debian 10 (**Buster**)
* (_in progress_) Debian 11 (**Bullseye**)

# Using from C/C++

This version of `libnode` can be used from both C and C++ with a simple Node-API interface:

```c
// !!! All napi calls for one given environment must
// !!! be made from the same thread that created it
// (except everything napi_threadsafe_function related)

// This the V8 engine, there must be only one
napi_platform platform;
// This is a V8 isolate, there may be multiple
napi_env env;
// This holds local references, when it is closed
// they become available to the GC
napi_handle_scope scope;
// These are JS values
napi_value global;
napi_value key;
napi_value cb;
napi_value result;

const char *main_script = "console.log('hello world'); "
    "function callMe() { console.log('called you'); }";

// Do only once
if (napi_create_platform(0, NULL, 0, NULL, NULL, 0, &platform) != napi_ok) {
    fprintf(stderr, "Failed creating the platform\n");
    return -1;
}

// Do for each environment (V8 isolate)
// 'hello world' will be printed here
if (napi_create_environment(platform, NULL, main_script, &env) != napi_ok) {
    fprintf(stderr, "Failed running JS\n");
    return -1;
}

// Here you can interact with the environment through Node-API env
// (refer to the Node-API doc)
if (napi_get_global(env, &global) != napi_ok) {
    fprintf(stderr, "Failed accessing the global object\n");
    return -1;
}
napi_create_string_utf8(env, "callMe", strlen("callMe"), &key);
if (napi_get_property(env, global, key, &cb) != napi_ok) {
    fprintf(stderr, "Failed accessing the global object\n");
    return -1;
}

// This cycle can be repeated
{
    // Call a JS function
    // V8 will run in this thread
    if (napi_call_function(env, global, cb, 0, NULL, &result) != napi_ok) {
        fprintf(stderr, "Failed calling JS callback\n");
        return -1;
    }
    // (optional) Call this to flush all pending async callbacks
    // V8 will run in this thread
    if (napi_run_environment(env) != napi_ok) {
        fprintf(stderr, "Failed flushing pending JS callbacks\n");
        return -1;
    }
}

// Shutdown everyhing
napi_close_handle_scope(env, scope);

if (napi_destroy_environment(env, NULL) != napi_ok) {
    return -1;
}

if (napi_destroy_platform(platform) != napi_ok) {
    fprintf(stderr, "Failed destroying the platform\n");
    return -1;
}
```

When using from C++, one can include `napi.h` and `env` can be converted to `Napi::Env` so that all the C++ convenience functions can be used.
