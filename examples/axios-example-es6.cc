#include <stdio.h>
#define NAPI_EXPERIMENTAL
#include <napi.h>

int main() {
    try {
        Napi::Platform platform;
        Napi::PlatformEnv env(platform);

        try {
            Napi::HandleScope scope(env);

            // import axios
            // The default bootstrap script creates a ES6-compatible
            // environment with a global.import() that is an async function
            Napi::Function import =
                env.Global().Get("import").As<Napi::Function>();

            // Async code should be called with MakeCallback instead of a
            // normal Call - otherwise the Promise/nextTick handlers might
            // not run
            Napi::Value axios_promise = import.MakeCallback(
                env.Global(), {Napi::String::New(env, "axios")});

            // import always returns a Promise for an object
            // If there is a default import, it is called default
            Napi::Object axios_import =
                axios_promise.As<Napi::Promise>().Await().ToObject();
            Napi::Object axios = axios_import.Get("default").ToObject();

            // As this is an async function, it will return immediately
            Napi::Promise r =
                axios.Get("get")
                    .As<Napi::Function>()
                    .Call({Napi::String::New(env, "https://www.google.com")})
                    .As<Napi::Promise>();
            // At this point the event loop is stopped, unless the function
            // returned an already resolved Promise, it won't get resolved
            // until the event loop is restarted
            // If the event loop is not restarted soon enough, the network
            // will eventually timeout - same as in Node.js

            // Promise resolve handler
            // (same as JS - we retrieve the `then` property, which is a
            // function, then we call it, passing a handler as argument
            // and the Promise as this)
            r.Get("then").As<Napi::Function>().Call(
                r,
                {Napi::Function::New(env, [](const Napi::CallbackInfo &info) {
                    // If you throw here, your program will get
                    // terminated - same as JS - but with a very cryptic
                    // message about `runMicroTasks` being undefined
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
            // (if you want to catch exceptions in `then` you have to attach
            // your handler to the value returned by `then` - here you are
            // attaching to the base Promise itself)
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

            // This will have the effect of a JS await - it will restart the
            // event loop
            // (ie one of the above 2 lambdas will run here)
            env.Run();
            
            // All async tasks have been completed
        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
        }
    } catch (napi_status r) {
        fprintf(stderr, "Failed initializing Node.js environment: %d\n",
                (int)r);
    }

    return 0;
}
