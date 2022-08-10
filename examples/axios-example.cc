#include <stdio.h>
#define NAPI_EXPERIMENTAL
#include <napi.h>

int main() {
    napi_platform platform;

    if (napi_create_platform(0, nullptr, 0, nullptr, nullptr, 0, &platform) !=
        napi_ok) {
        fprintf(stderr, "Failed creating the platform\n");
        return -1;
    }
    napi_env _env;
    if (napi_create_environment(platform, nullptr, nullptr, &_env) != napi_ok) {
        fprintf(stderr, "Failed running JS\n");
        return -1;
    }

    {
        Napi::Env env(_env);
        Napi::HandleScope scope(env);

        try {
            // require axios
            // The default bootstrap script creates a ES6/CJS-compatible
            // environment with global.require() and global.import()
            Napi::Function require =
                env.Global().Get("require").As<Napi::Function>();
            Napi::Object axios =
                require.Call({Napi::String::New(env, "axios")}).ToObject();

            // As this is an async function, it will return immediately
            // Async code should be called with MakeCallback instead of a
            // normal Call - otherwise the Promise/nextTick handlers might
            // not run
            Napi::Promise r =
                axios.Get("get")
                    .As<Napi::Function>()
                    .MakeCallback(
                        env.Global(),
                        {Napi::String::New(env, "https://www.google.com")})
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
                    // If you throw here, your program will get terminated -
                    // same as JS - but with a very cryptic message
                    // about `runMicroTasks` being undefined
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
            if (napi_run_environment(_env) != napi_ok) {
                fprintf(stderr, "Failed flushing async callbacks\n");
                return -1;
            }
            // All async tasks have been completed
        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
        }
    }

    if (napi_destroy_environment(_env, nullptr) != napi_ok) {
        return -1;
    }

    if (napi_destroy_platform(platform) != napi_ok) {
        fprintf(stderr, "Failed destroying the platform\n");
        return -1;
    }

    return 0;
}
