#import <node.h>
#import <v8.h>

using namespace v8;

void initialize(Local<Function> replyCallback);
void showNotification(Handle<String> object);