#import <Preferences/Preferences.h>
#import "globalHeaders.h"

#define url(x) [[UIApplication sharedApplication] openURL:[NSURL URLWithString:x]];

#define bounds [[UIScreen mainScreen] bounds]
#define HEIGHT bounds.size.height
#define WIDTH bounds.size.width

@implementation ScreenPainterListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"ScreenPainter" target:self] retain];
	}
	return _specifiers;
}
- (void)openTwitter {
	url(@"http://twitter.com/Sassoty");
}
- (void)openDonate {
	url(@"http://bit.ly/sassotypp");
}
- (void)openWebsite {
	url(@"http://sassoty.com");
}
@end

@implementation BrushListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Brush" target:self] retain];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(reloadTheSpecifiers:) 
        name:@"BrushReloadSpecifiers"
        object:nil];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
        NULL,
        (CFNotificationCallback)updatePreView,
        CFSTR("com.sassoty.screenpainter/preferencechanged"),
        NULL,
        CFNotificationSuspensionBehaviorDeliverImmediately);
	return _specifiers;
}
UIWindow* myWindow = nil;
UIView* preView = nil;
UIImageView* opacityPreview = nil;
CGFloat brush = nil;
CGFloat red = nil;
CGFloat green = nil;
CGFloat blue = nil;
CGFloat redS = nil;
CGFloat greenS = nil;
CGFloat blueS = nil;
CGFloat opacity = nil;
BOOL preViewIsShown = NO;
- (void)reloadTheSpecifiers:(NSNotification *)notification {
	reloadThePrefs();
	PSSpecifier* redSpecifier = [self specifierForID:@"red"];
	PSSpecifier* greenSpecifier = [self specifierForID:@"green"];
	PSSpecifier* blueSpecifier = [self specifierForID:@"blue"];
	[self setPreferenceValue:@(redS) specifier:redSpecifier];
	[self setPreferenceValue:@(greenS) specifier:greenSpecifier];
	[self setPreferenceValue:@(blueS) specifier:blueSpecifier];
	[self clearCache];
	[self reloadSpecifiers];
}
void reloadThePrefs(){

	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    brush = [prefs[@"brush"] floatValue];
    if(!prefs[@"brush"]) brush = 10.0;
    red = ([prefs[@"red"] floatValue])/255.0;
    if(!prefs[@"red"]) red = 0.0/255.0;
    green = ([prefs[@"green"] floatValue])/255.0;
    if(!prefs[@"green"]) green = 0.0/255.0;
    blue = ([prefs[@"blue"] floatValue])/255.0;
    if(!prefs[@"blue"]) blue = 0.0/255.0;
    opacity = [prefs[@"opacity"] floatValue];
    if(!prefs[@"opacity"]) opacity = 1.0;

    redS = ([prefs[@"red"] floatValue]);
    if(!prefs[@"red"]) redS = 0.0;
    greenS = ([prefs[@"green"] floatValue]);
    if(!prefs[@"green"]) greenS = 0.0;
    blueS = ([prefs[@"blue"] floatValue]);
    if(!prefs[@"blue"]) blueS = 0.0;

}
- (void)saveBrushPreset {

	UIAlertView* alert = [[UIAlertView alloc]
		initWithTitle:@"ScreenPainter"
		message:@"Would you like to save this as a preset?"
		delegate:self
		cancelButtonTitle:@"No"
		otherButtonTitles:@"Yes", nil];

	[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
	UITextField* name = [alert textFieldAtIndex:0];
    [name setPlaceholder:@"Label"];

	[alert show];[alert release];

}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSString* name = [[alertView textFieldAtIndex:0] text];
	if(buttonIndex==1){
		[self savePreset:name];
	}
}
- (void)savePreset:(NSString *)name {

	reloadThePrefs();

	NSString* filePath = [@"/Library/ScreenPainter/Brushes/" stringByAppendingString:name];
	NSString* content = [NSString stringWithFormat:@"%f\n%f\n%f", redS, greenS, blueS];

	[content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];

}
- (void)showPreview {

	if(preViewIsShown) return;

	reloadThePrefs();

	int daWidth = 170;
    int daHeight = 130;
	CGRect frame = CGRectMake(0,0,0,0);
    frame.origin.x = (bounds.size.width/2)-(daWidth/2);
    frame.origin.y = (bounds.size.height/2)-(daHeight/2);
    frame.size.width = daWidth;
    frame.size.height = daHeight;

	myWindow = [[UIWindow alloc] initWithFrame:frame];
	myWindow.windowLevel = UIWindowLevelStatusBar;
	[myWindow makeKeyAndVisible];

	preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, daWidth, daHeight)];
	preView.backgroundColor = [UIColor darkGrayColor];
	preView.alpha = 0.0;
	preView.layer.cornerRadius = 20;
	preView.layer.masksToBounds = YES;

	UITapGestureRecognizer *singleFingerTap = 
	  	[[UITapGestureRecognizer alloc] initWithTarget:self 
		action:@selector(handleSingleTap:)];
	[preView addGestureRecognizer:singleFingerTap];
	[singleFingerTap release];

	[myWindow addSubview:preView];

	UILabel* tapToDismiss = [[UILabel alloc] initWithFrame:CGRectMake((daWidth/2)-50, daHeight-40, 100, 40)];
    tapToDismiss.text = @"Tap to Dismiss";
    tapToDismiss.adjustsFontSizeToFitWidth = YES;
    tapToDismiss.numberOfLines = 1;
    tapToDismiss.textColor = [UIColor whiteColor];
    tapToDismiss.textAlignment = NSTextAlignmentCenter;

    [preView addSubview:tapToDismiss];

	opacityPreview = [[UIImageView alloc] initWithFrame:CGRectMake(((daWidth/2)-45), ((daHeight/2)-45)-8, 90, 90)];
	opacityPreview.alpha = 0.0;

    UIGraphicsBeginImageContext(opacityPreview.frame.size);
    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
    CGContextSetLineWidth(UIGraphicsGetCurrentContext(),brush);
    CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
    CGContextMoveToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),45, 45);
    CGContextStrokePath(UIGraphicsGetCurrentContext());
    opacityPreview.image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [myWindow addSubview:opacityPreview];

    [UIView animateWithDuration:0.65
	                      delay:0.0
	                    options: UIViewAnimationCurveEaseInOut
	                 animations:^{preView.alpha = 0.65;}
	                 completion:nil];
	[UIView animateWithDuration:0.65
	                      delay:0.0
	                    options: UIViewAnimationCurveEaseInOut
	                 animations:^{opacityPreview.alpha = 1.0;}
	                 completion:nil];

	preViewIsShown = YES;

}
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer {
	[UIView animateWithDuration:0.65
	                      delay:0.0
	                    options: UIViewAnimationCurveEaseInOut
	                 animations:^{opacityPreview.alpha = 0.0;}
	                 completion:nil];
	[UIView animateWithDuration:0.65
	                      delay:0.0
	                    options: UIViewAnimationCurveEaseInOut
	                 animations:^{preView.alpha = 0.0;}
	                 completion:^(BOOL){
	                 	[myWindow resignKeyWindow];
	                 	[myWindow release];
	                 	preViewIsShown = NO;
	                 }];
}
void updatePreView() {
	if(preViewIsShown){
		reloadThePrefs();
		UIGraphicsBeginImageContext(opacityPreview.frame.size);
		CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
		CGContextSetLineWidth(UIGraphicsGetCurrentContext(),brush);
		CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), red, green, blue, opacity);
		CGContextMoveToPoint(UIGraphicsGetCurrentContext(),45, 45);
		CGContextAddLineToPoint(UIGraphicsGetCurrentContext(),45, 45);
		CGContextStrokePath(UIGraphicsGetCurrentContext());
		[UIView animateWithDuration:0.35
	        delay:0.0
	        options: UIViewAnimationCurveEaseInOut
	        animations:^{opacityPreview.alpha = 0.0;}
	        completion:^(BOOL){
	        	opacityPreview.image = UIGraphicsGetImageFromCurrentImageContext();
	        	UIGraphicsEndImageContext();
	        	[UIView animateWithDuration:0.35
	        	    delay:0.0
	        	    options: UIViewAnimationCurveEaseInOut
	        	    animations:^{opacityPreview.alpha = 1.0;}
	        	    completion:nil];
	        }];
	}
}
@end

@interface SBScreenFlash : NSObject
+ (id)sharedInstance;
- (void)flash;
@end

@implementation FlashColorListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"FlashColor" target:self] retain];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(reloadMySpecifiers:) 
        name:@"FlashReloadSpecifiers"
        object:nil];
	return _specifiers;
}
CGFloat flashred = nil;
CGFloat flashgreen = nil;
CGFloat flashblue = nil;
CGFloat flashredS = nil;
CGFloat flashgreenS = nil;
CGFloat flashblueS = nil;
- (void)reloadMySpecifiers:(NSNotification *)notification {
	reloadMyPrefs();
	PSSpecifier* redSpecifier = [self specifierForID:@"flashred"];
	PSSpecifier* greenSpecifier = [self specifierForID:@"flashgreen"];
	PSSpecifier* blueSpecifier = [self specifierForID:@"flashblue"];
	[self setPreferenceValue:@(flashredS) specifier:redSpecifier];
	[self setPreferenceValue:@(flashgreenS) specifier:greenSpecifier];
	[self setPreferenceValue:@(flashblueS) specifier:blueSpecifier];
	[self clearCache];
	[self reloadSpecifiers];
}
void reloadMyPrefs(){

	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

    flashred = ([prefs[@"flashred"] floatValue])/255.0;
    if(!prefs[@"flashred"]) flashred = 0.0/255.0;
    flashgreen = ([prefs[@"flashgreen"] floatValue])/255.0;
    if(!prefs[@"flashgreen"]) flashgreen = 0.0/255.0;
    flashblue = ([prefs[@"flashblue"] floatValue])/255.0;
    if(!prefs[@"flashblue"]) flashblue = 0.0/255.0;

    flashredS = ([prefs[@"flashred"] floatValue]);
    if(!prefs[@"flashred"]) flashredS = 0.0;
    flashgreenS = ([prefs[@"flashgreen"] floatValue]);
    if(!prefs[@"flashgreen"]) flashgreenS = 0.0;
    flashblueS = ([prefs[@"flashblue"] floatValue]);
    if(!prefs[@"flashblue"]) flashblueS = 0.0;

}
- (void)saveFlashPreset {

	UIAlertView* alert = [[UIAlertView alloc]
		initWithTitle:@"ScreenPainter"
		message:@"Would you like to save this as a preset?"
		delegate:self
		cancelButtonTitle:@"No"
		otherButtonTitles:@"Yes", nil];

	[alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
	UITextField* name = [alert textFieldAtIndex:0];
    [name setPlaceholder:@"Label"];

	[alert show];[alert release];

}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSString* name = [[alertView textFieldAtIndex:0] text];
	if(buttonIndex==1){
		[self savePreset:name];
	}
}
- (void)savePreset:(NSString *)name {

	reloadMyPrefs();

	NSString* filePath = [@"/Library/ScreenPainter/Flashes/" stringByAppendingString:name];
	NSString* content = [NSString stringWithFormat:@"%f\n%f\n%f", flashredS, flashgreenS, flashblueS];

	[content writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];

}
- (void)showPreview{
	CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.sassoty.screenpainter/flashforpreview"),
        NULL,
        NULL,
        true
        );
}
@end

@implementation BrushPresetListController

- (void)viewDidLoad {

	[self.listArray removeAllObjects];

	[self.view setBackgroundColor:[UIColor whiteColor]];

	self.tabView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];

	self.tabView.delegate = self;
    self.tabView.dataSource = self;
    [self.tabView setAlwaysBounceVertical:YES];

    self.listArray = [[NSMutableArray alloc] init];

    NSError *error;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/ScreenPainter/Brushes/" error:&error];

	for(int i = 0; i < [directoryContents count]; i++){
		[self.listArray addObject:[directoryContents objectAtIndex:i]];
	}

    [self.view addSubview:self.tabView];
    [self.tabView reloadData];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.listArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Presets";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self loadRGBWithName:[self.listArray objectAtIndex:indexPath.row]];
    [self.tabView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)loadRGBWithName:(NSString*)name {

	NSString *filePath = [@"/Library/ScreenPainter/Brushes/" stringByAppendingString:name];

	NSString *fileContent = [NSString
		stringWithContentsOfFile:filePath
		encoding:NSUTF8StringEncoding
		error:nil];

	NSArray *contentArray = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSString *cRed = [contentArray objectAtIndex:0];
	NSString *cGreen = [contentArray objectAtIndex:1];
	NSString *cBlue = [contentArray objectAtIndex:2];

	NSLog(@"[ScreenPainter] Selected Brush Preset: %@ with: R:%@ G:%@ B:%@", name, cRed, cGreen, cBlue);

	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

	prefs[@"red"] = @([cRed floatValue]);
	prefs[@"green"] = @([cGreen floatValue]);
	prefs[@"blue"] = @([cBlue floatValue]);

	[prefs writeToFile:settingsPath atomically:YES];

	NSLog(@"[ScreenPainter] Prefs: %@", prefs);

	//reloadSpecifiers here
	[[NSNotificationCenter defaultCenter] 
        postNotificationName:@"BrushReloadSpecifiers" 
        object:nil];

	[self showPopup];

}

- (void)showPopup {

    int daWidth = 180;
    int daHeight = 115;
	CGRect frame = CGRectMake(0,0,0,0);
    frame.origin.x = (bounds.size.width/2)-(daWidth/2);
    frame.origin.y = (bounds.size.height/2)-(daHeight/2);
    frame.size.width = daWidth;
    frame.size.height = daHeight;

    UIWindow* myWindow = [[UIWindow alloc] initWithFrame:frame];
    myWindow.windowLevel = UIWindowLevelStatusBar;
    [myWindow makeKeyAndVisible];

    UIView* preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    preView.backgroundColor = [UIColor blackColor];
    preView.alpha = 0.0;
    preView.layer.cornerRadius = 20;
    preView.layer.masksToBounds = YES;

    [myWindow addSubview:preView];

    UILabel* loadedLabel = [[UILabel alloc] initWithFrame:CGRectMake((frame.size.width/2)-90, (frame.size.height/2)-70, 180, 140)];
    loadedLabel.text = @"Loaded!";
    loadedLabel.font = [UIFont systemFontOfSize:42.0];
    loadedLabel.numberOfLines = 1;
    loadedLabel.textColor = [UIColor whiteColor];
    loadedLabel.textAlignment = NSTextAlignmentCenter;

    [preView addSubview:loadedLabel];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options: UIViewAnimationCurveEaseInOut
                     animations:^{preView.alpha = 0.85;}
                     completion:^(BOOL){
                        [UIView animateWithDuration:0.55
                                              delay:0.09
                                            options: UIViewAnimationCurveEaseInOut
                                         animations:^{preView.alpha = 0.0;}
                                         completion:^(BOOL){
                                            [myWindow resignKeyWindow];
                                            [myWindow release];
                                         }];
                     }];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    //cell.textLabel.text = [NSString stringWithFormat:@"%@", str];

    NSString *cellName = [self.listArray objectAtIndex:indexPath.row];

    cell.textLabel.text = cellName;

    /*
    NSString *folderPath = [@"/Library/ScreenPainter/" stringByAppendingString:cellName];
    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Icon.png", folderPath]];
	*/

    return cell;
    
}

@end

@implementation FlashPresetListController

- (void)viewDidLoad {

	[self.listArray removeAllObjects];

	[self.view setBackgroundColor:[UIColor whiteColor]];

	self.tabView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT)];

	self.tabView.delegate = self;
    self.tabView.dataSource = self;
    [self.tabView setAlwaysBounceVertical:YES];

    self.listArray = [[NSMutableArray alloc] init];

    NSError *error;
	NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/ScreenPainter/Flashes/" error:&error];

	for(int i = 0; i < [directoryContents count]; i++){
		[self.listArray addObject:[directoryContents objectAtIndex:i]];
	}

    [self.view addSubview:self.tabView];
    [self.tabView reloadData];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.listArray count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Presets";
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self loadRGBWithName:[self.listArray objectAtIndex:indexPath.row]];
	[self.tabView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)loadRGBWithName:(NSString*)name {

	NSString *filePath = [@"/Library/ScreenPainter/Flashes/" stringByAppendingString:name];

	NSString *fileContent = [NSString
		stringWithContentsOfFile:filePath
		encoding:NSUTF8StringEncoding
		error:nil];

	NSArray *contentArray = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSString *cRed = [contentArray objectAtIndex:0];
	NSString *cGreen = [contentArray objectAtIndex:1];
	NSString *cBlue = [contentArray objectAtIndex:2];

	NSLog(@"[ScreenPainter] Selected Flash Preset: %@ with: R:%@ G:%@ B:%@", name, cRed, cGreen, cBlue);

	NSString *settingsPath = [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Preferences/com.sassoty.screenpainter.plist"];
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];

	prefs[@"flashred"] = @([cRed floatValue]);
	prefs[@"flashgreen"] = @([cGreen floatValue]);
	prefs[@"flashblue"] = @([cBlue floatValue]);

	[prefs writeToFile:settingsPath atomically:YES];

	NSLog(@"[ScreenPainter] Prefs: %@", prefs);

	//reloadSpecifiers here
	[[NSNotificationCenter defaultCenter] 
        postNotificationName:@"FlashReloadSpecifiers" 
        object:nil];

	[self showPopup];

}

- (void)showPopup {

    int SIZE = 230;
    if(bounds.size.height==480) SIZE = 190;

    CGRect frame = CGRectMake(0,0,0,0);
    frame.origin.x = 60;
    frame.origin.y = SIZE;
    frame.size.width = bounds.size.width-120;
    frame.size.height = bounds.size.height-(SIZE*2);

    UIWindow* myWindow = [[UIWindow alloc] initWithFrame:frame];
    myWindow.windowLevel = UIWindowLevelStatusBar;
    [myWindow makeKeyAndVisible];

    UIView* preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    preView.backgroundColor = [UIColor blackColor];
    preView.alpha = 0.0;
    preView.layer.cornerRadius = 20;
    preView.layer.masksToBounds = YES;

    [myWindow addSubview:preView];

    UILabel* loadedLabel = [[UILabel alloc] initWithFrame:CGRectMake((frame.size.width/2)-90, (frame.size.height/2)-70, 180, 140)];
    loadedLabel.text = @"Loaded!";
    loadedLabel.font = [UIFont systemFontOfSize:42.0];
    loadedLabel.numberOfLines = 1;
    loadedLabel.textColor = [UIColor whiteColor];
    loadedLabel.textAlignment = NSTextAlignmentCenter;

    [preView addSubview:loadedLabel];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options: UIViewAnimationCurveEaseInOut
                     animations:^{preView.alpha = 0.85;}
                     completion:^(BOOL){
                        [UIView animateWithDuration:0.55
                                              delay:0.09
                                            options: UIViewAnimationCurveEaseInOut
                                         animations:^{preView.alpha = 0.0;}
                                         completion:^(BOOL){
                                            [myWindow resignKeyWindow];
                                            [myWindow release];
                                         }];
                     }];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    //cell.textLabel.text = [NSString stringWithFormat:@"%@", str];

    NSString *cellName = [self.listArray objectAtIndex:indexPath.row];

    cell.textLabel.text = cellName;

    /*
    NSString *folderPath = [@"/Library/ScreenPainter/" stringByAppendingString:cellName];
    cell.imageView.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Icon.png", folderPath]];
	*/

    return cell;
    
}

@end

// vim:ft=objc
