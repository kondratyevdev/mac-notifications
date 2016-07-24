#import "NSObject+V8.h"

@implementation NSString (v8)

- (Local<Value>)v8Value {
  return Local<Value>(String::NewFromUtf8(Isolate::GetCurrent(), [self UTF8String]));
}

+ (NSString*)stringWithV8String:(Local<String>)str {
  String::Utf8Value utf8(str);
  return [NSString stringWithUTF8String:*utf8];
}

@end

@implementation NSDictionary (BVJSONString)

- (NSString *)bv_jsonStringWithPrettyPrint:(BOOL)prettyPrint {
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                       options:(NSJSONWritingOptions)    (prettyPrint ? NSJSONWritingPrettyPrinted : 0)
                                                         error:&error];
    
    if (!jsonData) {
        NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}
@end