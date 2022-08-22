#include <stdio.h>
#define NAPI_EXPERIMENTAL
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
