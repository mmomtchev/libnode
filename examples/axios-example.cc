#include <stdio.h>
#define NAPI_EXPERIMENTAL
#include <napi.h>

int main() {
    napi_platform platform;

    if (napi_create_platform(0, nullptr, 0, nullptr, nullptr, 0, &platform) != napi_ok) {
        fprintf(stderr, "Failed creating the platform\n");
        return -1;
    }
    napi_env _env;
    if (napi_create_environment(platform, nullptr, nullptr, &_env) !=
        napi_ok) {
        fprintf(stderr, "Failed running JS\n");
        return -1;
    }

    {
        Napi::Env env(_env);
        Napi::HandleScope scope(env);

        try {
            // require axios
            Napi::Function require =
                env.Global().Get("require").As<Napi::Function>();
            Napi::Object axios =
                require.Call({Napi::String::New(env, "axios")}).ToObject();

            Napi::Promise r =
                axios.Get("get")
                    .As<Napi::Function>()
                    .Call({Napi::String::New(env, "https://www.google.com")})
                    .As<Napi::Promise>();

            // Promise resolve handler
            r.Get("then").As<Napi::Function>().Call(
                r, {Napi::Function::New(axios.Env(), [](const Napi::CallbackInfo
                                                            &info) {
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
            r.Get("catch").As<Napi::Function>().Call(
                r, {Napi::Function::New(
                       axios.Env(), [](const Napi::CallbackInfo &info) {
                           Napi::HandleScope scope(info.Env());
                           if (!info[0].IsNull()) {
                               printf("Axios error: %s",
                                      info[0].As<Napi::Error>().what());
                               return;
                           }
                       })});

            if (napi_run_environment(_env) != napi_ok) {
                fprintf(stderr, "Failed flushing async callbacks\n");
                return -1;
            }
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
