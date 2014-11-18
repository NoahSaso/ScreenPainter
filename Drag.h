@interface DragView : UIView <UIActionSheetDelegate, UITextViewDelegate>
@end

@interface SBScreenFlash : NSObject
+(id)mySharedInstance;
+(id)sharedInstance;
+(id)mainScreenFlasher;
-(void)flash;
-(void)flashWhiteWithCompletion:(id)arg1;
- (void)flashColor:(id)arg1;
- (void)flashColor:(id)arg1 withCompletion:(id)arg2;
@end
