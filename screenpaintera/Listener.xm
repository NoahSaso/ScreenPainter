#import "libactivator.h"
@interface ScreenPainterA : NSObject<LAListener> 
{} 
@end

@implementation ScreenPainterA

-(void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.sassoty.screenpainter/showscreenshot"),
        NULL,
        NULL,
        true
        );
}

+(void)load {
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	[[LAActivator sharedInstance] registerListener:[self new] forName:@"com.sassoty.screenpainter"];
	[p release];
}
@end
