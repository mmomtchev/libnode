#include <stdio.h>
#define NAPI_EXPERIMENTAL
#define NAPI_EMBEDDING
#include <node_api_embedding.h>

#include <napi.h>

// This example implements basic (no encoding) redirection
// of stdout/stderr and stdin blackholing
// Not only this allows to retrieve the stdout output of
// the Node.js code, it also prevents Node.js from
// switching stdin/stdout/stderr to non-blocking mode
// which might interfere with your program
const char *stdio_redir = "delete process.stdin;"
                          "delete process.stdout;"
                          "delete process.stderr;"
                          "const {Writable} = require('stream');"
                          "process.stdout = new Writable({"
                          "  write(buf, enc, cb) {"
                          // This is the custom handler
                          "    stdout_handler(buf.toString());"
                          "    cb();"
                          "  }"
                          "});"
                          "process.stderr = process.stdout;"
                          "const {Readable} = require('stream');"
                          "process.stdin = new Readable({read(){}});"
                          "process.stdin.push(null);";

// This function will get called to write to stdout/stderr
static Napi::Value stdout_handler(const Napi::CallbackInfo &info) {
    Napi::Env env = info.Env();

    if (info.Length() != 1 || !info[0].IsString()) {
        throw Napi::TypeError::New(env,
                                   "write must have a single string argument");
    }

    // Redirect all console.* output to stderr
    fprintf(stderr, "[libnode] %s\n",
            info[0].ToString().Utf8Value().c_str());
    return env.Undefined();
}

int main() {
    try {
        Napi::Platform platform;
        Napi::PlatformEnv env(platform, stdio_redir);

        try {
            Napi::HandleScope scope(env);

            // Install the stdio handler
            env.Global().Set("stdout_handler", Napi::Function::New(env, stdout_handler));

            // Get a reference to require
            Napi::Function require =
                env.Global().Get("require").As<Napi::Function>();

            // require('./console.js') and get the default export as a function
            Napi::Function print =
                require({Napi::String::New(env, "./console.js")})
                    .As<Napi::Function>();

            // Call this function
            print({Napi::String::New(env, "from JS through C++")});

        } catch (const Napi::Error &e) {
            fprintf(stderr, "Caught a JS exception: %s\n", e.what());
        }
    } catch (napi_status r) {
        fprintf(stderr, "Failed initializing Node.js environment: %d\n",
                (int)r);
    }

    return 0;
}
