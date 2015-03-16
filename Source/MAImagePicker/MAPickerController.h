//
//  MAPickerController.h
//

#import <UIKit/UIKit.h>

typedef enum
{
    MAMediaPhotoAL, // ALAsset with photo
    MAMediaVideoAL, // ALAsset with video
    MAMediaPhotoPH, // PHAsset with photo
    MAMediaVideoPH  // PHAsset with video
} MAMediaType;

@protocol MAPickerDelegate <NSObject>

// calls with nil of picker closed without selecting images
- (void)pickerOnOk: (NSArray*)items;

@end

//=================================================================================

typedef enum
{
    MAPhotoMiss,   /* access not selected */
    MAPhotoNo2,    /* no access for some reason */
    MAPhotoNo,     /* access declined by user */
    MAPhotoOK      /* access ok */
} MAPhotoAccess;

@class PHCachingImageManager;

//=================================================================================

@interface MAPickerController : UITableViewController

+ (instancetype)sharedInstance;

// maxSel - max items to select (0 - no limit)
- (instancetype)initWithDelegate: (id<MAPickerDelegate>)delegate maxSel: (int)maxSel;
- (void)onCancel;
- (void)onOk;

- (NSMutableArray*)selObjects;
- (NSMutableArray*)selItems;
- (int)maxSel;
- (PHCachingImageManager*)imgCache;

+ (MAPhotoAccess)photosAccess;
+ (MAPhotoAccess)cameraAccess;

+ (int)thumbSz;

@end
