#include <node.h>
#include <v8.h>

#import "notifications.h"

using namespace v8;

void initializeFunc(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = Isolate::GetCurrent();
    HandleScope scope(isolate);

    Handle<Function> callback = Handle<Function>::Cast(args[0]);
    initialize(callback);
}

void showNotificationFunc(const v8::FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = Isolate::GetCurrent();
    HandleScope scope(isolate);

    if (args[0]->IsString()) {
        Handle<String> obj = args[0]->ToString();
        showNotification(obj);
    }
}

void Init(Handle<Object> exports) {
    NODE_SET_METHOD(exports, "initialize", initializeFunc);
    NODE_SET_METHOD(exports, "showNotification", showNotificationFunc);
}

NODE_MODULE(hello, Init)
