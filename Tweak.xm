#import "Drag.h"
#import <Preferences/Preferences.h>

#define kBounds [[UIScreen mainScreen] bounds]

UIWindow* wind = nil;
DragView* drawView = nil;

NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
BOOL isEnabled = YES;
BOOL hasShownPrompt = NO;

@interface SpringBoard <UIAlertViewDelegate>
@end

BOOL openLater = NO;

BOOL isAlreadyOn = NO;

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 {
    %orig;
    
    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
    if(!prefs) prefs = [[NSMutableDictionary alloc] init];

    isEnabled = [prefs[@"enabled"] boolValue];
    if(prefs[@"enabled"]==nil) isEnabled = YES;
    hasShownPrompt = [prefs[@"hasShownPrompt"] boolValue];
    if(prefs[@"hasShownPrompt"]==nil) hasShownPrompt = NO;

    if(!hasShownPrompt) {
    	UIAlertView* alert = [[UIAlertView alloc]
    				initWithTitle:@"ScreenPainter"
    				message:@"Thank you for downloading ScreenPainter! I worked very hard on this tweak, and included as much customizability as possible, to give you the best experience. Please consider sending a small donation over PayPal to sassoty@gmail.com! Thank you!"
    				delegate:self
    				cancelButtonTitle:@"No thanks"
    				otherButtonTitles:@"Sure, let's go!", nil];
    	[alert show];[alert release];

        prefs[@"hasShownPrompt"] = @(YES);
        [prefs writeToFile:settingsPath atomically:YES];
    }
}

%new
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if(buttonIndex==1){
        openLater = YES;
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/sassotypp"]];
	}
}

%end

%hook SBDeviceLockController

- (BOOL)attemptDeviceUnlockWithPassword:(id)arg1 appRequested:(BOOL)arg2 {
    BOOL origVal = %orig;
    if(origVal && openLater) {
        openLater = NO;
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/sassotypp"]];
    }
    return origVal;
}

%end

void reloadPreferences() {

    NSLog(@"[ScreenPainter] reloadingPreferences");

    [prefs release];
	prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
        if(!prefs) prefs = [[NSMutableDictionary alloc] init];

    isEnabled = [prefs[@"enabled"] boolValue];
    if(prefs[@"enabled"]==nil) isEnabled = YES;
    hasShownPrompt = [prefs[@"hasShownPrompt"] boolValue];
    if(prefs[@"hasShownPrompt"]==nil) hasShownPrompt = NO;

}

void showScreenShot() {
    if(isAlreadyOn) return;
    reloadPreferences();

    wind = [[UIWindow alloc] initWithFrame:kBounds];
    //wind = [[UIApplication sharedApplication] keyWindow];
    wind.windowLevel = UIWindowLevelStatusBar;
    [wind makeKeyAndVisible];

    UIViewController* vC = [[UIViewController alloc] init];
    drawView = [[DragView alloc] initWithFrame:kBounds];
    //wind.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.5f];

    vC.view = drawView;

    wind.rootViewController = vC;

    NSLog(@"[ScreenPainter] Added draw view");
    isAlreadyOn = YES;
}

%hook SBScreenShotter

- (void)saveScreenshot:(BOOL)screenshot {
    if(!isEnabled){
        %orig;
        return;
    }
    showScreenShot();
}

%end

void removeWindow() {

	[drawView removeFromSuperview];
	[drawView release];

    NSLog(@"[ScreenPainter] No drawView");

	[wind resignKeyWindow];
	[wind release];

    NSLog(@"[ScreenPainter] No window");

	drawView = nil;
	wind = nil;

	NSLog(@"[ScreenPainter] Kicked window from screen");
    isAlreadyOn = NO;
}

void flashScreenForPreview(){
	SBScreenFlash* sbFlash = [%c(SBScreenFlash) sharedInstance];
    [sbFlash flash];
    NSLog(@"[ScreenPainter] Preview Flashed!");
}

%ctor {

	reloadPreferences();

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)reloadPreferences,
        CFSTR("com.sassoty.screenpainter/preferencechanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)removeWindow,
        CFSTR("com.sassoty.screenpainter/remove"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)flashScreenForPreview,
        CFSTR("com.sassoty.screenpainter/flashforpreview"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)showScreenShot,
        CFSTR("com.sassoty.screenpainter/showscreenshot"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

}
