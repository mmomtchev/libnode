#include <stdio.h>
#define NAPI_EXPERIMENTAL
#include <napi.h>

int main() {
    // !!! All napi calls for one given environment must
    // !!! be made from the same thread that created it
    // (except everything napi_threadsafe_function related)

    // This the V8 engine, there must be only one
    napi_platform platform;

    const char *main_script = "console.log('hello world'); "
                              "function callMe(s) { console.log('called ' + s); }"
                              // or you can use vm.runInThisContext
                              "global.callMe = callMe;";

    // Do only once
    if (napi_create_platform(0, NULL, 0, NULL, NULL, 0, &platform) != napi_ok) {
        fprintf(stderr, "Failed creating the platform\n");
        return -1;
    }

    // This is a V8 isolate, there may be multiple
    napi_env _env;
    // Do for each environment (V8 isolate)
    // 'hello world' will be printed here
    if (napi_create_environment(platform, NULL, main_script, &_env) != napi_ok) {
        fprintf(stderr, "Failed running JS\n");
        return -1;
    }

    {
        Napi::Env env(_env);
        Napi::HandleScope scope(env);
        // This holds local references, when it is closed
        // they become available to the GC
        // Here you can interact with the environment through Node::Env
        // (refer to the node-addon-api doc)

        try {
            Napi::Object global = env.Global();
            Napi::Function cb = global.Get("callMe").As<Napi::Function>();

            // This cycle can be repeated
            {
                // Call a JS function
                // V8 will run in this thread
                cb.Call({Napi::String::New(env, "you")});
                // (optional) Call this to flush all pending async callbacks
                // V8 will run in this thread
                if (napi_run_environment(env) != napi_ok) {
                    fprintf(stderr, "Failed flushing pending JS callbacks\n");
                    return -1;
                }
            }
        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
        }
    }

    if (napi_destroy_environment(_env, NULL) != napi_ok) {
        return -1;
    }

    if (napi_destroy_platform(platform) != napi_ok) {
        fprintf(stderr, "Failed destroying the platform\n");
        return -1;
    }

    return 0;
}
