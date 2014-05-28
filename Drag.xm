#import "Drag.h"
#import "DragTextView.h"
#import <UIKit/UIKit.h>

#define bounds [[UIScreen mainScreen] bounds]

extern "C" UIImage* _UICreateScreenUIImage();

//Define variables
UIImageView* mainDrawImage = nil;
UIView* preView;
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

BOOL isOn = NO;

BOOL preViewIsVisible = NO;

BOOL isEditingText = NO;

BOOL changingColor = NO;
UIView* chgColorView = nil;
UIImageView* chgPreView = nil;

static NSString* settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
static NSMutableDictionary* prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
static BOOL isEnabled = YES;
static BOOL isFlashEnabled = YES;

@interface SpringBoard
- (void)_giveUpOnMenuDoubleTap;
- (void)cancelMenuButtonRequests;
@end

%hook SpringBoard

- (void)_handleMenuButtonEvent{

    if(isOn){
        NSLog(@"[ScreenPainter] Pressed home button!");
        [self _giveUpOnMenuDoubleTap];
        [self cancelMenuButtonRequests];
        [[NSNotificationCenter defaultCenter] 
            postNotificationName:@"com.sassoty.screenpainter/homebutton" 
            object:nil];
    }else if(changingColor) {
        [self _giveUpOnMenuDoubleTap];
        [self cancelMenuButtonRequests];
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
    }else if(isEditingText){
        [self _giveUpOnMenuDoubleTap];
        [self cancelMenuButtonRequests];
    }else { %orig; }

}

%end

%hook SBScreenFlash

- (void)flash {

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

@implementation DragView

- (id)initWithFrame:(CGRect)frame {
	if(self = [super initWithFrame:frame]){
        reloadPrefs();
        isOn = YES;
        //Define observer
        [[NSNotificationCenter defaultCenter] addObserver:self
            selector:@selector(dismissView:) 
            name:@"com.sassoty.screenpainter/homebutton"
            object:nil];
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
    frame.origin.x = (bounds.size.width/2)-(daWidth/2);
    frame.origin.y = (bounds.size.height/2)-(daHeight/2);
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

    preViewIsVisible = YES;

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options: UIViewAnimationCurveEaseInOut
                     animations:^{preView.alpha = 0.85;}
                     completion:^(BOOL){
                        [UIView animateWithDuration:0.55
                                              delay:0.29
                                            options: UIViewAnimationCurveEaseInOut
                                         animations:^{preView.alpha = 0.0;}
                                         completion:^(BOOL){
                                            [preView removeFromSuperview];
                                            [preView release];
                                            preViewIsVisible = NO;
                                            NSLog(@"[ScreenPainter] Draw view gone");
                                         }];
                     }];

}

- (BOOL)canBecomeFirstResponder{ 
    return YES; 
}

- (void)pressedI {
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
                break;
            case 5:
                [self saveToCameraRoll];
                isOn = YES;
                break;
            case 6:
                [self copyToClipboard];
                isOn = YES;
                break;
            case 7:
                [self saveToCameraRoll];
                [self copyToClipboard];
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

    chgColorView = [[UIView alloc] initWithFrame:bounds];
    [chgColorView setBackgroundColor:[UIColor whiteColor]];
    chgColorView.alpha = 0.0;

    CGRect frame = CGRectMake(40, 80, 260, 10);
    UISlider* brushSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* redSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* greenSlider = [[UISlider alloc] initWithFrame:frame];
    frame.origin.y+=50;
    UISlider* blueSlider = [[UISlider alloc] initWithFrame:frame];

    CGRect frameLabel = CGRectMake(10, 80-5, 20, 15);
    UILabel* sLab = [[UILabel alloc] initWithFrame:frameLabel];
    sLab.font = [UIFont systemFontOfSize:12.5];
    sLab.text = @"S:";
    frameLabel.origin.y+=50;
    UILabel* rLab = [[UILabel alloc] initWithFrame:frameLabel];
    rLab.font = [UIFont systemFontOfSize:14.0];
    rLab.text = @"R:";
    rLab.textColor = [UIColor redColor];
    frameLabel.origin.y+=50;
    UILabel* gLab = [[UILabel alloc] initWithFrame:frameLabel];
    gLab.font = [UIFont systemFontOfSize:14.0];
    gLab.text = @"G:";
    gLab.textColor = [UIColor greenColor];
    frameLabel.origin.y+=50;
    UILabel* bLab = [[UILabel alloc] initWithFrame:frameLabel];
    bLab.font = [UIFont systemFontOfSize:14.0];
    bLab.text = @"B:";
    bLab.textColor = [UIColor blueColor];

    [chgColorView addSubview:sLab];
    [chgColorView addSubview:rLab];
    [chgColorView addSubview:gLab];
    [chgColorView addSubview:bLab];

    [brushSlider addTarget:self action:@selector(updateBrush:) forControlEvents:UIControlEventValueChanged];
    [brushSlider setBackgroundColor:[UIColor clearColor]];
    brushSlider.minimumValue = 1.0;
    brushSlider.maximumValue = 70.0;
    brushSlider.continuous = YES;
    brushSlider.value = brush;

    [redSlider addTarget:self action:@selector(updateRed:) forControlEvents:UIControlEventValueChanged];
    [redSlider setBackgroundColor:[UIColor clearColor]];
    redSlider.minimumValue = 0.0;
    redSlider.maximumValue = 255.0;
    redSlider.continuous = YES;
    redSlider.value = red*255.0;

    [greenSlider addTarget:self action:@selector(updateGreen:) forControlEvents:UIControlEventValueChanged];
    [greenSlider setBackgroundColor:[UIColor clearColor]];
    greenSlider.minimumValue = 0.0;
    greenSlider.maximumValue = 255.0;
    greenSlider.continuous = YES;
    greenSlider.value = green*255.0;

    [blueSlider addTarget:self action:@selector(updateBlue:) forControlEvents:UIControlEventValueChanged];
    [blueSlider setBackgroundColor:[UIColor clearColor]];
    blueSlider.minimumValue = 0.0;
    blueSlider.maximumValue = 255.0;
    blueSlider.continuous = YES;
    blueSlider.value = blue*255.0;

    [chgColorView addSubview:brushSlider];
    [chgColorView addSubview:redSlider];
    [chgColorView addSubview:greenSlider];
    [chgColorView addSubview:blueSlider];

    chgPreView = [[UIImageView alloc] initWithFrame:CGRectMake(((bounds.size.width/2)-45), ((bounds.size.height/2)-45)+100, 90, 90)];

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

    [self addSubview:chgColorView];
    [self bringSubviewToFront:chgColorView];

    [UIView animateWithDuration:0.65
        delay:0.0
        options: UIViewAnimationCurveEaseInOut
        animations:^{chgColorView.alpha = 1.0;}
        completion:nil];

}
- (void)addTextBox {
    CGRect frameForTV = CGRectMake((bounds.size.width/2)-50, (bounds.size.height/2)-50, 100, 100);
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

- (void)dismissView:(NSNotification* )notification {

    if(preViewIsVisible){
        NSLog(@"[ScreenPainter] Remove preView so screenshot doesn't suck!");
        preView.alpha = 0.0;
        [preView removeFromSuperview];
        [preView release];
        preView = nil;
    }

    latestScreenImage = [self getScreenImage];

    SBScreenFlash* sbFlash = [%c(SBScreenFlash) sharedInstance];
    [sbFlash flash];
    NSLog(@"[ScreenPainter] Flashed!");

    [self performSelector:@selector(showEndAlert) withObject:nil afterDelay:0.4];

}

- (UIImage* )getScreenImage {
    //Get screenshot
    return _UICreateScreenUIImage();
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

%ctor {

    reloadPrefs();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)reloadPrefs,
        CFSTR("com.sassoty.screenpainter/preferencechanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);

}
