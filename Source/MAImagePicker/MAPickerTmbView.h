//
//  MAPickerTmbView.h
//

#import <UIKit/UIKit.h>

@class ALAssetsGroup;
@class MAPickerListController5;

@interface MAPickerTmbView : UIScrollView

- (instancetype)initWithFrame: (CGRect)frame album: (ALAssetsGroup*)album vc: (MAPickerListController5*)vc;
+ (void)addVideoLabel: (UIView*)view sz: (int)sz dur: (int)d;

@end
