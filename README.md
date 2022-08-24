# Current libnode packages with Node-API / node-addon-api interface for Ubuntu and Debian

[![](https://developers.google.com/open-source/gsoc/resources/downloads/GSoC-Horizontal.png)](https://summerofcode.withgoogle.com/programs/2022/projects/ZsLHGYTg)

[![](https://raw.githubusercontent.com/OSGeo/osgeo/master/marketing/branding/logo/osgeo-logo-cmyk.svg)](https://www.osgeo.org/)

This repository contains the packaging used to generate the Ubuntu and Debian (_upcoming_) packages of `libnode` with [PR #43542](https://github.com/nodejs/node/pull/43542) bringing full Node-API and `node-addon-api` support to `libnode`.

Ubuntu PPA: https://launchpad.net/~mmomtchev/+archive/ubuntu/libnode

Unlike the distributions built-in packages, these packages:

- Include [PR#43542](https://github.com/nodejs/node/pull/43542) allowing to embed the Node.js entirely through the binary stable Node-API from both C and C++. This PR might or might not get merged (it is currently under discussions)
- Are similar to the [NodeSource binary distributions](https://github.com/nodesource/distributions)
- libnode headers are installed in `/usr/include/libnode` to avoid a conflict with an eventual NodeSource `nodejs` installation - you should make sure that `/usr/include/libnode` appears before `/usr/include/node` in your compiler search path
- Use self-contained packages that include all Node.js dependencies in the same executable - as very few people use both `libnode` and `libuv` or `v8` independently in the same project bundling these separately has no real benefit
- Provide current versions even for old distributions
- Are not supported on all hardware platforms
- Are not restrained by Debian dogma (some of the included dependencies are not fully GPL-compatible - but it is still qualifies as free software)
- `node-addon-api` is also available as a separate package

The packages have been developed as part of GSoC 2022 on a project sponsored by the Open Source Geospatial Foundation and are copyright by Google and distributed under MIT License.

I am maintaining them as a courtesy to the open source community.

# Status

Highly experimental

# Basic Principle of Operation

The C/C++ code is linked against a shared library (about 80Mb) which includes a fully self-contained Node.js runtime in which the standard bootstrap code has been modified.

Running `napi_create_platform` initializes Node.js/V8 and running `napi_create_environment` creates an isolate which can be roughly compared to one `worker_thread` in Node.js. An environment can be accessed only by the C/C++ thread which created it. When calling into JavaSscript, Node.js/V8 run in the context of the calling thread.

A special method, `napi_run_environment` allows the draining of the event loop - which also happens in the context of the worker thread. While the C/C++ code is running, the event loop is not. This means that if the C/C++ code does not call `napi_run_environment` often enough, background network transfers will eventually overrun their buffers and will start failing. If the C/C++ code is very CPU-intensive, the all Node.js/V8 interaction should probably be relegated to a separate thread. This is basically the same rule as when combining async code with CPU-intensive tasks in Node.js. The only difference is that JS must exit its currently running function to resume the background processing, while C/C++ must call `napi_run_environment`.

All JS objects are managed in the Node.js/V8 heap and may be accessed only through the `napi_` primitives and only in the thread that created the environment. All the `napi_*` functions come from the standard Node-API that is used for Node.js native addons - these are intercepted by the creation of a special `napi_env` that represents the embedded environment. The structure that renders this possible is *hidden* in the environment instance data - so `napi_set_instance_data` and `napi_get_instance_data` are never to be used on this environment.

## Known Issues

* `runMicroTasks is undefined` - Your program is raising an exception in a C/C++ async handler that will lead to program termination anyway - it is just that the message is very cryptic - this happens because the exception is processed in a context without builtins
* `axios_example` crashes - Your installed `libnode` version does not match the example
* The inspector is missing an attachment point for `inspect-brk`: this can be worked around by adding `require('inspector').waitForDebugger(); debugger;` in the beginning of the source file (which is in fact the bootstrapper) or refer to [debugger-example.cc](https://github.com/mmomtchev/libnode/blob/main/examples/debugger-example.cc) for a clean solution.
* Node.js may switch stdio/stdout/stderr to non-blocking mode on UNIX when piping, see [stdio-redir-example.cc](https://github.com/mmomtchev/libnode/blob/main/examples/stdio-redir-example.cc) for how to deal with this.
* `error: ‘napi_create_platform’ was not declared in this scope` - make sure your code includes this before the includes:
    ```c
    #define NAPI_EXPERIMENTAL
    #define NAPI_EMBEDDING
    ```

# Supported Platforms

Node.js 16.x and (_in progress_) Node.js 18.x on

- Ubuntu 18.04 (**Bionic**)
- Ubuntu 20.04 (**Focal**)
- Ubuntu 22.04 (**Jammy**)
- (_in progress_) Debian 10 (**Buster**)
- (_in progress_) Debian 11 (**Bullseye**)

# Installation

```shell
sudo add-apt-repository ppa:mmomtchev/libnode
sudo apt update
sudo apt install libnode93 libnode-dev # C only
sudo apt install node-addon-api # with C++
```

# Building from source on other systems

Node.js 16.x branch

```shell
git clone -b napi-libnode-v16.x https://github.com/mmomtchev/node.git
cd node && ./configure --shared && make -j4
```

Node.js main branch

```shell
git clone -b napi-libnode https://github.com/mmomtchev/node.git
cd node && ./configure --shared && make -j4
```

C++ API extensions
```shell
git clone -b napi-embedding https://github.com/mmomtchev/node-addon-api.git
// Then include `napi.h` from $(pwd)/node-addon-api
```

# Using from C

This version of `libnode` can be used from both C and C++ with a simple Node-API interface:

Compile with:

```shell
gcc -I/usr/include/libnode -o libnode-napi-example libnode-napi-example.c -lnode
```

```c
#include <stdio.h>
#include <string.h>
#define NAPI_EXPERIMENTAL
#include <node_api.h>

int main() {
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
                              "function callMe() { console.log('called you'); }"
                              // or you can use vm.runInThisContext
                              "global.callMe = callMe;";

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

    return 0;
}
```

# Using from C++

Compile with

```shell
g++ -I/usr/include/libnode -I/usr/include/node -o libnode-napi libnode-napi-example.cc -lnode
```

```cpp
#include <stdio.h>
#define NAPI_EXPERIMENTAL
#define NAPI_EMBEDDING
#include <napi.h>

int main() {
    // !!! All napi calls for one given environment must
    // !!! be made from the same thread that created it
    // (except everything napi_threadsafe_function related)

    try {
        // This the V8 engine, there must be only one
        Napi::Platform platform;

        // This is the custom bootstrap script if you require any
        // (or you can use the default which provides require and import)
        const char *main_script =
            "console.log('hello world'); "
            "function callMe(s) { console.log('called ' + s); }"
            // or you can use vm.runInThisContext
            "global.callMe = callMe;";
        // This is a V8 isolate, there may be multiple
        // 'hello world' will be printed here
        Napi::PlatformEnv env(platform, main_script);

        try {
            // This holds local references, when it is closed
            // they become available to the GC
            // Here you can interact with the environment through Node::Env
            // (refer to the node-addon-api doc)
            Napi::HandleScope scope(env);
            Napi::Object global = env.Global();
            Napi::Function callMe = global.Get("callMe").As<Napi::Function>();

            // This cycle can be repeated
            {
                // Call a JS function
                // V8 will run in this thread
                callMe({Napi::String::New(env, "you")});
                // (optional) Call this to flush all pending async callbacks
                // V8 will run in this thread
                env.Run();
            }
        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
        }
    } catch (napi_status r) {
        fprintf(stderr, "Failed initializing the JS environment: %d\n", (int)r);
    }

    return 0;
}
```

# Loading `node_modules` from C++

`libnode` supports loading of both CJS and ES6 modules from C and C++, refer to
[CJS](https://github.com/mmomtchev/libnode/blob/main/examples/axios-example.cc) and [ES6](https://github.com/mmomtchev/libnode/blob/main/examples/axios-example-es6.cc)

```cpp
#include <stdio.h>
#define NAPI_EXPERIMENTAL
#define NAPI_EMBEDDING
#include <napi.h>

int main() {
    try {
        Napi::Platform platform;
        Napi::PlatformEnv env(platform);

        try {
            Napi::HandleScope scope(env);

            // require axios
            // The default bootstrap script creates a ES6/CJS-compatible
            // environment with global.require() and global.import()
            Napi::Function require =
                env.Global().Get("require").As<Napi::Function>();
            Napi::Object axios =
                require({Napi::String::New(env, "axios")}).ToObject();

            // As this is an async function, it will return immediately
            // Async code should be called with MakeCallback instead of
            // a normal Call - otherwise the Promise/nextTick handlers
            // might not run
            Napi::Promise r =
                axios.Get("get")
                    .As<Napi::Function>()
                    .MakeCallback(
                        env.Global(),
                        {Napi::String::New(env, "https://www.google.com")})
                    .As<Napi::Promise>();
            // At this point the event loop is stopped, unless the
            // function returned an already resolved Promise, it won't
            // get resolved until the event loop is restarted If the
            // event loop is not restarted soon enough, the network will
            // eventually timeout - same as in Node.js

            // Promise resolve handler
            // (same as JS - we retrieve the `then` property, which is a
            // function, then we call it, passing a handler as argument
            // and the Promise as this)
            r.Get("then").As<Napi::Function>().Call(
                r,
                {Napi::Function::New(env, [](const Napi::CallbackInfo &info) {
                    // If you throw here, your program will get
                    // terminated - same as JS - but with a very
                    // cryptic message about `runMicroTasks` being
                    // undefined
                    Napi::HandleScope scope(info.Env());
                    if (!info[0].IsObject()) {
                        printf("Axios returned: %s\n",
                               info[0].ToString().Utf8Value().c_str());
                        return;
                    }
                    std::string data =
                        info[0].ToObject().Get("data").ToString().Utf8Value();
                    printf("Result is:\n\n%s\n", data.c_str());
                })});

            // Promise reject handler
            // (if you want to catch exceptions in `then` you have to
            // attach your handler to the value returned by `then` -
            // here you are attaching to the base Promise itself)
            r.Get("catch").As<Napi::Function>().Call(
                r,
                {Napi::Function::New(env, [](const Napi::CallbackInfo &info) {
                    Napi::HandleScope scope(info.Env());
                    if (!info[0].IsNull()) {
                        printf("Axios error: %s",
                               info[0].As<Napi::Error>().what());
                        return;
                    }
                })});

            // This will have the effect of a JS await - it will restart
            // the event loop (ie one of the above 2 lambdas will run
            // here)
            env.Run();

            // All async tasks have been completed
        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
            return -1;
        }
    } catch (napi_status r) {
        fprintf(stderr, "Failed initializing Node.js environment: %d\n",
                (int)r);
        return -1;
    }

    return 0;
}
```

*made in Annecy*

*made on solar power*