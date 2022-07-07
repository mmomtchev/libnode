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
