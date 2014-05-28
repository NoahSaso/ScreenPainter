@interface DragView : UIView <UIActionSheetDelegate, UITextViewDelegate>
@end

@interface SBScreenFlash : NSObject
+ (id)sharedInstance;
- (void)flash;
- (void)flashColor:(id)arg1;
@end
