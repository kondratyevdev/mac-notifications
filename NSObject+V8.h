#import <node.h>
#import <v8.h>
#import <Cocoa/Cocoa.h>

using namespace v8;

@interface NSString (v8)

- (Local<Value>)v8Value;

+ (NSString*)stringWithV8String:(Local<String>)str;

@end

@interface NSDictionary (BVJSONString)

- (NSString *)bv_jsonStringWithPrettyPrint:(BOOL)prettyPrint;

@end