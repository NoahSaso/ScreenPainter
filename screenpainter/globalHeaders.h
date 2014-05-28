@interface ScreenPainterListController: PSListController {
}
- (void)openTwitter;
- (void)openDonate;
- (void)openWebsite;
@end

@interface BrushListController: PSListController <UIAlertViewDelegate>
- (void)showPreview;
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;
- (void)saveBrushPreset;
- (void)savePreset:(NSString *)name;
@end

@interface FlashColorListController: PSListController {
}
- (void)showPreview;
- (void)saveFlashPreset;
- (void)savePreset:(NSString *)name;
@end

@interface BrushPresetListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
}
@property (strong, nonatomic) UITableView *tabView;
@property (strong, nonatomic) NSMutableArray *listArray;
@end

@interface FlashPresetListController : PSViewController <UITableViewDelegate, UITableViewDataSource> {
}
@property (strong, nonatomic) UITableView *tabView;
@property (strong, nonatomic) NSMutableArray *listArray;
@end
