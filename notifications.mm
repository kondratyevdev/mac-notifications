#include <node.h>
#include <v8.h>
#import <Cocoa/Cocoa.h>

#import "notifications.h"

#import "NSObject+V8.h"

using namespace v8;

Persistent<Function> persistentCallback;

@interface NotificationsHandler: NSObject<NSUserNotificationCenterDelegate>

+ (instancetype)sharedInstance;

@end

@implementation NotificationsHandler

+ (instancetype)sharedInstance {
    static NotificationsHandler *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [NotificationsHandler new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)showNotification:(Handle<String>)object {
    NSString *jsonString = [NSString stringWithV8String:object->ToString()];
    
    NSError *error = nil;
    NSMutableDictionary *json = [[NSJSONSerialization
                 JSONObjectWithData: [jsonString dataUsingEncoding:NSUTF8StringEncoding]
                 options:0
                 error:&error] mutableCopy];

    NSString *title = json[@"title"];
    NSString *subtitle = json[@"subtitle"];
    NSString *informativeText = json[@"informativeText"];
    NSString *soundName = json[@"soundName"];
    if (!soundName) {
        soundName = NSUserNotificationDefaultSoundName;
    }

    
    BOOL hasReplyButton = json[@"hasReplyButton"] ? [json[@"hasReplyButton"] boolValue] : false;
    NSString *responsePlaceholder = json[@"responsePlaceholder"];
    
    NSImage *contentImage = nil;
    NSString *contentImageString = json[@"contentImage"];
    if (contentImageString != nil) {
        [json removeObjectForKey:@"contentImage"];

        NSURL *url = [NSURL URLWithString:contentImageString];
        NSData *imageData = [NSData dataWithContentsOfURL:url];
        contentImage = [[NSImage alloc] initWithData:imageData];
    }
    
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = title;
    notification.subtitle = subtitle;
    notification.informativeText = informativeText;
    notification.soundName = nil;
    notification.hasReplyButton = hasReplyButton;
    if (hasReplyButton) {
        notification.responsePlaceholder = responsePlaceholder;
    }
    notification.contentImage = contentImage;

    if ([@"no-sound" isEqualToString:soundName]) {
        notification.userInfo = @{@"jsonString": [json bv_jsonStringWithPrettyPrint:false]};
    } else {
        notification.userInfo = @{@"soundName": soundName, @"jsonString": [json bv_jsonStringWithPrettyPrint:false]};
    }

    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
        didDeliverNotification:(NSUserNotification *)notification {
    
    id<NSUserNotificationCenterDelegate> delegate = (id<NSUserNotificationCenterDelegate>)[NSApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(userNotificationCenter:didDeliverNotification:)]) {
        [delegate userNotificationCenter:center didDeliverNotification:notification];
    }
    
    if (notification.userInfo != nil && notification.userInfo[@"soundName"] != nil) {
        NSSound *sound = [NSSound soundNamed:notification.userInfo[@"soundName"]];
        if (sound != nil) {
            [sound stop];
            sound.currentTime = 0;
            [sound play];
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center
       didActivateNotification:(NSUserNotification *)notification {
    
    id<NSUserNotificationCenterDelegate> delegate = (id<NSUserNotificationCenterDelegate>)[NSApplication sharedApplication].delegate;
    if ([delegate respondsToSelector:@selector(userNotificationCenter:didActivateNotification:)]) {
        [delegate userNotificationCenter:center didActivateNotification:notification];
    }
    
    if (notification.activationType == NSUserNotificationActivationTypeReplied){        
        [self sendReplyCallback:notification replyText: notification.response.string];
    } else {
        [self sendActiveCallback:notification];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification {
    
    id<NSUserNotificationCenterDelegate> delegate = (id<NSUserNotificationCenterDelegate>)[NSApplication sharedApplication].delegate;
    
    BOOL result = true;
    if ([delegate respondsToSelector:@selector(userNotificationCenter:shouldPresentNotification:)]) {
        result = [delegate userNotificationCenter:center shouldPresentNotification:notification];
    }
    return result;
}

- (void)sendReplyCallback:(NSUserNotification *)notification replyText:(NSString *)replyText {
    Isolate *isolate = Isolate::GetCurrent();
    
    NSString *json = notification.userInfo != nil ? notification.userInfo[@"jsonString"] : nil;
    if (json == nil) {
        json = @"{}";
    }
    
    const unsigned argc = 3;
    Local<Value> argv[argc] = { [json v8Value], [@"reply" v8Value], [replyText v8Value] };
    Local<Function>::New(isolate, persistentCallback)->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

- (void)sendActiveCallback:(NSUserNotification *)notification {
    Isolate *isolate = Isolate::GetCurrent();
    
    NSString *json = notification.userInfo != nil ? notification.userInfo[@"jsonString"] : nil;
    if (json == nil) {
        json = @"{}";
    }
    
    const unsigned argc = 2;
    Local<Value> argv[argc] = { [json v8Value], [@"active" v8Value] };
    Local<Function>::New(isolate, persistentCallback)->Call(isolate->GetCurrentContext()->Global(), argc, argv);
}

@end


void initialize(Handle<Function> сallback) {
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = [NotificationsHandler sharedInstance];
    
    persistentCallback.Reset(Isolate::GetCurrent(), сallback);
}

void showNotification(Handle<String> object) {
    [[NotificationsHandler sharedInstance] showNotification:object];
}