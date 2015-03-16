//
//  MAPickerListController.h
//

#import <UIKit/UIKit.h>

@class ALAssetsGroup;

@interface MAPickerListController : UICollectionViewController

// item is ALAssetsGroup or NSArray
- (instancetype)initWithItem: (id)item isPh: (BOOL)isPh;

@end

//=================================================================================

@interface MAPickerListController5 : UIViewController

- (instancetype)initWithAlbum: (ALAssetsGroup*)item;
- (void)reloadDone;

@end
