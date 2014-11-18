#import "Drag.h"
#import "DragTextView.h"
#import <UIKit/UIKit.h>

#import "iOSVersion/iOSVersion.m"

#define kBounds [[UIScreen mainScreen] bounds]

extern "C" UIImage* _UICreateScreenUIImage();

//Define variables
UIImageView* mainDrawImage = nil;
UIView* preView = nil;
UIImage* latestScreenImage = nil;
UIColor* bgColor = [[UIColor clearColor] colorWithAlphaComponent:0.5f];
BOOL mouseSwiped = NO;
BOOL isEraser = NO;
CGPoint lastPoint;
CGFloat red = 0.0/255.0;
CGFloat green = 0.0/255.0;
CGFloat blue = 0.0/255.0;
CGFloat brush = 10.0;

CGFloat flashred = 255.0/255.0;
CGFloat flashgreen = 255.0/255.0;
CGFloat flashblue = 255.0/255.0;
CGFloat flashopacity = 1.0;

UIButton* optionBn = nil;
UIButton* shareBn = nil;
UIButton* doneBn = nil;

BOOL isOn = NO;

BOOL isEditingText = NO;

BOOL changingColor = NO;
UIView* chgColorView = nil;
UIImageView* chgPreView = nil;

static NSString* settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
static NSMutableDictionary* prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
static BOOL isEnabled, isFlashEnabled = YES;
static BOOL disableHome = NO;

BOOL justExited = NO;

@interface SpringBoard : UIApplication
- (void)cancelMenuButtonRequests;
- (void)clearMenuButtonTimer;
@end

@interface UIImage (Private)
+ (UIImage *)imageNamed:(NSString *)named inBundle:(NSBundle *)bundle;
@end

%hook SBScreenFlash
%group iOSOther
%new +(id)mySharedInstance {
    return [self sharedInstance];
}
-(void)flash {

    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    isFlashEnabled = [prefs[@"flashenabled"] boolValue];
    if(prefs[@"flashenabled"]==nil) isFlashEnabled = YES;
    flashred = ([prefs[@"flashred"] floatValue])/255.0;
    if(!prefs[@"flashred"]) flashred = 255.0/255.0;
    flashgreen = ([prefs[@"flashgreen"] floatValue])/255.0;
    if(!prefs[@"flashgreen"]) flashgreen = 255.0/255.0;
    flashblue = ([prefs[@"flashblue"] floatValue])/255.0;
    if(!prefs[@"flashblue"]) flashblue = 255.0/255.0;
    flashopacity = [prefs[@"flashopacity"] floatValue];
    if(!prefs[@"flashopacity"]) flashopacity = 1.0;

    if(isFlashEnabled){
        UIColor* fColor = [UIColor colorWithRed:flashred green:flashgreen blue:flashblue alpha:flashopacity];
        [self flashColor:fColor];
    }else{
        %orig;
    }

}
%end
%group iOS8
%new +(id)mySharedInstance {
    return [self mainScreenFlasher];
}
%new -(void)flash {

    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    isFlashEnabled = [prefs[@"flashenabled"] boolValue];
    if(prefs[@"flashenabled"]==nil) isFlashEnabled = YES;
    flashred = ([prefs[@"flashred"] floatValue])/255.0;
    if(!prefs[@"flashred"]) flashred = 255.0/255.0;
    flashgreen = ([prefs[@"flashgreen"] floatValue])/255.0;
    if(!prefs[@"flashgreen"]) flashgreen = 255.0/255.0;
    flashblue = ([prefs[@"flashblue"] floatValue])/255.0;
    if(!prefs[@"flashblue"]) flashblue = 255.0/255.0;
    flashopacity = [prefs[@"flashopacity"] floatValue];
    if(!prefs[@"flashopacity"]) flashopacity = 1.0;

    if(isFlashEnabled){
        UIColor* fColor = [UIColor colorWithRed:flashred green:flashgreen blue:flashblue alpha:flashopacity];
        [self flashColor:fColor withCompletion:nil];
    }else{
        [self flashWhiteWithCompletion:nil];
    }

}
%end
%end

%group All
%hook SpringBoard

- (void)_handleMenuButtonEvent{

    if(justExited) {
        [self cancelMenuButtonRequests];
        [self clearMenuButtonTimer];
        justExited = NO;
        %orig;
    }

    if(isOn && !disableHome) {
        NSLog(@"[ScreenPainter] Pressed home button!");
        [self cancelMenuButtonRequests];
        [self clearMenuButtonTimer];

        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"com.sassoty.screenpainter/homebutton" 
            object:nil];
    }else if(changingColor) {
        [self cancelMenuButtonRequests];
        [self clearMenuButtonTimer];
        changingColor = NO;
        isOn = YES;
        [UIView animateWithDuration:0.65
            delay:0.0
            options: UIViewAnimationCurveEaseInOut
            animations:^{chgColorView.alpha = 0.0;}
            completion:^(BOOL){
                [chgColorView removeFromSuperview];
                [chgColorView release];
                NSLog(@"[ScreenPainter] Removed change color from screen!");
            }];
    }else if(isEditingText || (isOn && disableHome)) {
        [self cancelMenuButtonRequests];
        [self clearMenuButtonTimer];
    }
    else { %orig; }

}

%end

@implementation DragView

- (id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]){
        reloadPrefs();

        isOn = YES;

        //Define observer
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(dismissView) 
            name:@"com.sassoty.screenpainter/homebutton"
            object:nil];

        //Define buttons
        optionBn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [optionBn addTarget:self action:@selector(pressedOption) forControlEvents:UIControlEventTouchUpInside];
        optionBn.frame = CGRectMake(25, 25, 30, 30);
        optionBn.alpha = 0.0;

        shareBn = [UIButton buttonWithType:UIButtonTypeCustom];
        [shareBn setBackgroundImage:[UIImage imageNamed:@"shareButton" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/ScreenPainter.bundle"]] forState:UIControlStateNormal];
        [shareBn addTarget:self action:@selector(showShareSheet) forControlEvents:UIControlEventTouchUpInside];
        shareBn.frame = CGRectMake(kBounds.size.width-47.5, 24, 22.5, 28.8);
        shareBn.alpha = 0.0;

        doneBn = [UIButton buttonWithType:UIButtonTypeSystem];
        [doneBn setTitle:@"Done" forState:UIControlStateNormal];
        [doneBn addTarget:self action:@selector(dismissView) forControlEvents:UIControlEventTouchUpInside];
        doneBn.frame = CGRectMake((kBounds.size.width / 2) - 25, 25, 50, 40);
        doneBn.alpha = 0.0;

        [self addSubview: optionBn];
        [self addSubview: shareBn];
        [self addSubview: doneBn];

        [self becomeFirstResponder];
        [self showDraw:frame];
	}
	return self;
}

- (void)showDraw:(CGRect)frame1 {

    NSLog(@"[ScreenPainter] Showing image view...");
    //Define the view to drag in
    mainDrawImage = [[UIImageView alloc] initWithFrame:frame1];
    mainDrawImage.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.01];
    //Add drag view to view
    [self addSubview:mainDrawImage];

    NSLog(@"[ScreenPainter] Showing draw...");

    int daWidth = 165;
    int daHeight = 115;
    CGRect frame = CGRectMake(0,0,0,0);
    frame.origin.x = (kBounds.size.width/2)-(daWidth/2);
    frame.origin.y = (kBounds.size.height/2)-(daHeight/2);
    frame.size.width = daWidth;
    frame.size.height = daHeight;

    preView = [[UIView alloc] initWithFrame:frame];
    preView.backgroundColor = [UIColor blackColor];
    preView.alpha = 0.0;
    preView.layer.cornerRadius = 20;
    preView.layer.masksToBounds = YES;

    UILabel* drawLabel = [[UILabel alloc] initWithFrame:CGRectMake((frame.size.width/2)-90, (frame.size.height/2)-70, 180, 140)];
    drawLabel.text = @"Draw!";
    drawLabel.font = [UIFont systemFontOfSize:48.0];
    drawLabel.numberOfLines = 1;
    drawLabel.textColor = [UIColor whiteColor];
    drawLabel.textAlignment = NSTextAlignmentCenter;

    [preView addSubview:drawLabel];

    [self addSubview:preView];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options: UIViewAnimationCurveEaseInOut
                     animations:^{preView.alpha = 0.85; optionBn.alpha = 1.0; shareBn.alpha = 1.0; doneBn.alpha = 1.0;}
                     completion:^(BOOL){
                        [UIView animateWithDuration:0.55
                                              delay:0.29
                                            options: UIViewAnimationCurveEaseInOut
                                         animations:^{preView.alpha = 0.0;}
                                         completion:^(BOOL){
                                            /*
                                            [preView removeFromSuperview];
                                            [preView release];
                                            */
                                            NSLog(@"[ScreenPainter] Draw view gone");
                                         }];
                     }];

}

/*
- (BOOL)canBecomeFirstResponder{ 
    return YES; 
}
*/

- (void)showShareSheet {

    [UIView animateWithDuration:0.35
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{preView.alpha = 0.0; optionBn.alpha = 0.0; shareBn.alpha = 0.0; doneBn.alpha = 0.0;}
        completion:^(BOOL){
            UIImage* imageToShare = [self getScreenImage];
            NSLog(@"Got screen image!");

            SBScreenFlash* sbFlash = [%c(SBScreenFlash) mySharedInstance];
            [sbFlash flash];
            NSLog(@"[ScreenPainter] Flashed!");

            Ivar ivar = class_getInstanceVariable([UIView class], "_viewDelegate");
            UIViewController *controller = object_getIvar(self, ivar);

            UIActivityViewController* activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[imageToShare] applicationActivities:nil];
            [activityVC setCompletionHandler:^(NSString* activityType, BOOL) {
                if(!activityType) {
                    [self reload];
                    return;
                }
                changingColor = NO;
                isOn = NO;
                [self removeMe];
            }];
            //activityVC.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll, UIActivityTypeCopyToPasteboard];
            [controller presentViewController:activityVC animated:YES completion:nil];
    }];

}

- (void)pressedOption {
    if(isEditingText) {
        UIAlertView *alert = [[UIAlertView alloc]
            initWithTitle:@"ScreenPainter"
            message:@"Select an action"
            delegate:self
            cancelButtonTitle:@"Cancel"
            otherButtonTitles:
            @"Stop Editing",
            @"Delete",
            nil];
        [alert setTag:2];
        [alert show];[alert release];
    }else {
        [self promptForShake];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    isEditingText = YES;
    isOn = NO;
    [self bringSubviewToFront:textView];
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    isEditingText = NO;
    isOn = YES;
}

- (void)promptForShake {
    NSLog(@"[ScreenPainter] Shake Prompt!");

    UIAlertView* alert = [[UIAlertView alloc]
        initWithTitle:@"ScreenPainter"
        message:@"Select an action"
        delegate:self
        cancelButtonTitle:@"Cancel"
        otherButtonTitles:
        @"Clear drawing",
        @"Clear text boxes",
        @"Clear all",
        @"Change color",
        (isEraser ? @"Switch to color" : @"Switch to eraser"),
        @"Add text box",
        nil];
    [alert show];[alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag==2){
        if(buttonIndex==1){
            [self endEditing:YES];
        }else if(buttonIndex==2){
            NSArray* subs = [self subviews];
            DragTextView* viewToRemove = [subs objectAtIndex:[subs count]-1];
            [viewToRemove removeFromSuperview];
            [viewToRemove release];
        }
    }else if(alertView.tag==3){
        switch(buttonIndex) {
            case 1:
                [self saveToCameraRoll];
                [self removeMe];
                break;
            case 2:
                [self copyToClipboard];
                [self removeMe];
                break;
            case 3:
                [self saveToCameraRoll];
                [self copyToClipboard];
                [self removeMe];
                break;
            case 4:
                isOn = YES;
                [self reload];
                break;
            case 5:
                [self saveToCameraRoll];
                [self reload];
                isOn = YES;
                break;
            case 6:
                [self copyToClipboard];
                [self reload];
                isOn = YES;
                break;
            case 7:
                [self saveToCameraRoll];
                [self copyToClipboard];
                [self reload];
                isOn = YES;
                break;
            default:
                [self removeMe];
                break;
        }
    }else{
        switch(buttonIndex){
            case 1:
                [self clearImg];
                break;
            case 2:
                [self clearTxt];
                break;
            case 3:
                [self clearImg];
                [self clearTxt];
                break;
            case 4:
                [self showColorChange];
                break;
            case 5:
                isEraser = !isEraser;
                break;
            case 6:
                [self addTextBox];
                break;
            default:
                break;
        }
    }
}

- (void)reload {
    [UIView animateWithDuration:0.35
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{optionBn.alpha = 1.0; shareBn.alpha = 1.0; doneBn.alpha = 1.0;}
        completion:^(BOOL){
            NSLog(@"[ScreenPainter] Reloaded!");
        }];
}

- (void)showEndAlert {

    UIAlertView* alert = [[UIAlertView alloc]
        initWithTitle:@"ScreenPainter"
        message:@"Select an action"
        delegate:self
        cancelButtonTitle:@"Delete"
        otherButtonTitles:
        @"Save to Camera Roll",
        @"Copy to Clipboard",
        @"Both",
        @"Keep Editing",
        @"Save + Keep Editing",
        @"Copy + Keep Editing",
        @"Both + Keep Editing",
        nil];
    [alert setTag:3];
    [alert show];[alert release];

    isOn = NO;

}

- (void)clearImg {
    mainDrawImage.image = nil;
    NSLog(@"[ScreenPainter] Cleared image!");
}
- (void)clearTxt {
    [self endEditing:YES];
    for(id view in [self subviews]){
        if([view isKindOfClass:[DragTextView class]]) {
            [view removeFromSuperview];
            [view release];
        }
    }
    NSLog(@"[ScreenPainter] Cleared text!");
}
- (void)showColorChange {

    NSLog(@"[ScreenPainter] Change color!");

    if(changingColor) return;

    isOn = NO;
    changingColor = YES;

    CGRect theNewBounds = kBounds;
    theNewBounds.size.height-=20;
    theNewBounds.origin.y = 20;
    chgColorView = [[UIView alloc] initWithFrame:theNewBounds];
    [chgColorView setBackgroundColor:[UIColor whiteColor]];
    chgColorView.alpha = 0.0;

    CGRect frame = CGRectMake(40, 50, kBounds.size.width - 80, 25);
    UISlider* brushSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* redSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* greenSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* blueSlider = [[UISlider alloc] initWithFrame:frame];

    [brushSlider addTarget:self action:@selector(updateBrush:) forControlEvents:UIControlEventValueChanged];
    [brushSlider setBackgroundColor:[UIColor clearColor]];
    brushSlider.minimumValue = 1.0;
    brushSlider.maximumValue = 70.0;
    brushSlider.continuous = YES;
    brushSlider.value = brush;
    brushSlider.minimumTrackTintColor = [UIColor darkGrayColor];

    [redSlider addTarget:self action:@selector(updateRed:) forControlEvents:UIControlEventValueChanged];
    [redSlider setBackgroundColor:[UIColor clearColor]];
    redSlider.minimumValue = 0.0;
    redSlider.maximumValue = 255.0;
    redSlider.continuous = YES;
    redSlider.value = red*255.0;
    redSlider.minimumTrackTintColor = [UIColor redColor];

    [greenSlider addTarget:self action:@selector(updateGreen:) forControlEvents:UIControlEventValueChanged];
    [greenSlider setBackgroundColor:[UIColor clearColor]];
    greenSlider.minimumValue = 0.0;
    greenSlider.maximumValue = 255.0;
    greenSlider.continuous = YES;
    greenSlider.value = green*255.0;
    greenSlider.minimumTrackTintColor = [UIColor greenColor];

    [blueSlider addTarget:self action:@selector(updateBlue:) forControlEvents:UIControlEventValueChanged];
    [blueSlider setBackgroundColor:[UIColor clearColor]];
    blueSlider.minimumValue = 0.0;
    blueSlider.maximumValue = 255.0;
    blueSlider.continuous = YES;
    blueSlider.value = blue*255.0;
    blueSlider.minimumTrackTintColor = [UIColor blueColor];

    [chgColorView addSubview:brushSlider];
    [chgColorView addSubview:redSlider];
    [chgColorView addSubview:greenSlider];
    [chgColorView addSubview:blueSlider];

    chgPreView = [[UIImageView alloc] initWithFrame:CGRectMake(((kBounds.size.width/2)-45), ((kBounds.size.height/2)-45)+70, 90, 90)];

    UIGraphicsBeginImageContext(chgPreView.frame.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(),brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    chgPreView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [chgColorView addSubview:chgPreView];

    UIButton* exitBn = [UIButton buttonWithType:UIButtonTypeSystem];
    [exitBn addTarget:self action:@selector(exitChgColorView) forControlEvents:UIControlEventTouchUpInside];
    [exitBn setTitle:@"Exit" forState:UIControlStateNormal];
    exitBn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22];
    exitBn.titleLabel.textAlignment = NSTextAlignmentCenter;
    exitBn.frame = CGRectMake((kBounds.size.width / 2) - 30, (chgPreView.frame.origin.y+90)+35, 60, 40);
    [chgColorView addSubview:exitBn];

    [self addSubview:chgColorView];
    [self bringSubviewToFront:chgColorView];

    [UIView animateWithDuration:0.4
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{chgColorView.alpha = 1.0;}
        completion:nil];

}
- (void)exitChgColorView {
    changingColor = NO;
    isOn = YES;
    [UIView animateWithDuration:0.4
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{chgColorView.alpha = 0.0;}
        completion:^(BOOL){
            [chgColorView removeFromSuperview];
            [chgColorView release];
            NSLog(@"[ScreenPainter] Removed change color from screen!");
        }];
}
- (void)addTextBox {
    CGRect frameForTV = CGRectMake((kBounds.size.width/2)-50, (kBounds.size.height/2)-50, 100, 100);
    DragTextView* newTextView = [[DragTextView alloc] initWithFrame:frameForTV];
    newTextView.backgroundColor = [[UIColor clearColor] colorWithAlphaComponent:0.47f];
    newTextView.font = [UIFont systemFontOfSize:15.0];
    newTextView.textColor = [UIColor whiteColor];
    newTextView.delegate = self;
    newTextView.layer.cornerRadius = 15;
    newTextView.layer.masksToBounds = YES;
    [self addSubview:newTextView];
    isOn = NO;
}

- (void)updateBrush:(id)sender {
    UISlider* sendee = (UISlider *)sender;
    brush = sendee.value;
    [self updatePreview];
}
- (void)updateRed:(id)sender {
    UISlider* sendee = (UISlider *)sender;
    red = (sendee.value)/255.0;
    [self updatePreview];
}
- (void)updateGreen:(id)sender {
    UISlider* sendee = (UISlider *)sender;
    green = (sendee.value)/255.0;
    [self updatePreview];
}
- (void)updateBlue:(id)sender {
    UISlider* sendee = (UISlider *)sender;
    blue = (sendee.value)/255.0;
    [self updatePreview];
}

- (void)updatePreview {

    NSLog(@"[ScreenPainter] New Preview!");

    UIGraphicsBeginImageContext(chgPreView.frame.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(),brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    chgPreView.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

}

void reloadPrefs() {

    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    isEnabled = [prefs[@"enabled"] boolValue];
    if(prefs[@"enabled"]==nil) isEnabled = YES;
    isFlashEnabled = [prefs[@"flashenabled"] boolValue];
    if(prefs[@"flashenabled"]==nil) isFlashEnabled = YES;
    disableHome = [prefs[@"disablehome"] boolValue];
    if(prefs[@"disablehome"]==nil) disableHome = NO;

    brush = [prefs[@"brush"] floatValue];
    if(!prefs[@"brush"]) brush = 10.0;
    red = ([prefs[@"red"] floatValue])/255.0;
    if(!prefs[@"red"]) red = 0.0/255.0;
    green = ([prefs[@"green"] floatValue])/255.0;
    if(!prefs[@"green"]) green = 0.0/255.0;
    blue = ([prefs[@"blue"] floatValue])/255.0;
    if(!prefs[@"blue"]) blue = 0.0/255.0;

    flashred = ([prefs[@"flashred"] floatValue])/255.0;
    if(!prefs[@"flashred"]) flashred = 255.0/255.0;
    flashgreen = ([prefs[@"flashgreen"] floatValue])/255.0;
    if(!prefs[@"flashgreen"]) flashgreen = 255.0/255.0;
    flashblue = ([prefs[@"flashblue"] floatValue])/255.0;
    if(!prefs[@"flashblue"]) flashblue = 255.0/255.0;
    flashopacity = [prefs[@"flashopacity"] floatValue];
    if(!prefs[@"flashopacity"]) flashopacity = 1.0;

    NSLog(@"[ScreenPainter] Done reloading prefs");

}

- (void)dismissView {

    [UIView animateWithDuration:0.35
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{preView.alpha = 0.0; optionBn.alpha = 0.0; shareBn.alpha = 0.0; doneBn.alpha = 0.0;}
        completion:^(BOOL){
            latestScreenImage = [self getScreenImage];
            NSLog(@"Got screen image!");

            SBScreenFlash* sbFlash = [%c(SBScreenFlash) mySharedInstance];
            [sbFlash flash];
            NSLog(@"[ScreenPainter] Flashed!");

            [self performSelector:@selector(showEndAlert) withObject:nil afterDelay:0.4];
    }];

}

- (UIImage* )getScreenImage {
    //Get screenshot
    NSLog(@"Getting screen image....");
    UIImage *screenImage = _UICreateScreenUIImage();
    return screenImage;
}

- (void)copyToClipboard {
    [UIPasteboard generalPasteboard].image = latestScreenImage;
    NSLog(@"[ScreenPainter] Saved screenshot to clipboard");
}

- (void)saveToCameraRoll {
    //Save screenshot
    UIImageWriteToSavedPhotosAlbum(latestScreenImage, nil, nil, nil);
    NSLog(@"[ScreenPainter] Wrote screenshot to camera roll");
}

- (void)removeMe {
    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:@"com.sassoty.screenpainter/homebutton"
        object:nil];
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.sassoty.screenpainter/remove"),
        NULL,
        NULL,
        true
        );
    justExited = YES;
}

- (void)touchesBegan:(NSSet* )touches withEvent:(UIEvent* )event {
    if(isOn){
        mouseSwiped = NO;
        UITouch* touch = [touches anyObject];
        lastPoint = [touch locationInView:self];
    }
}
 
- (void)touchesMoved:(NSSet* )touches withEvent:(UIEvent* )event {
    if(isOn){
        mouseSwiped = YES;
        UITouch* touch = [touches anyObject];
        CGPoint currentPoint = [touch locationInView:self];
        
        UIGraphicsBeginImageContext(self.frame.size);
        [mainDrawImage.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

        CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
        CGContextSetBlendMode(UIGraphicsGetCurrentContext(),(isEraser ? kCGBlendModeClear : kCGBlendModeNormal));
        CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush );

        CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
        CGContextBeginPath(UIGraphicsGetCurrentContext());
        CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
        CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), currentPoint.x, currentPoint.y);
        
        CGContextStrokePath(UIGraphicsGetCurrentContext());
        mainDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        lastPoint = currentPoint;
    }
}
 
- (void)touchesEnded:(NSSet* )touches withEvent:(UIEvent* )event {
    if(isOn){
        if(!mouseSwiped) {
            UIGraphicsBeginImageContext(self.frame.size);
            [mainDrawImage.image drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
            CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
            CGContextSetLineWidth(UIGraphicsGetCurrentContext(), brush);
            CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, 1.0);
            CGContextMoveToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), lastPoint.x, lastPoint.y);
            CGContextStrokePath(UIGraphicsGetCurrentContext());
            CGContextFlush(UIGraphicsGetCurrentContext());
            mainDrawImage.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
}

@end
%end

%ctor {

    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        %init(iOS8);
    }else {
        %init(iOSOther);
    }
    %init(All);

    reloadPrefs();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)reloadPrefs,
        CFSTR("com.sassoty.screenpainter/preferencechanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

}
