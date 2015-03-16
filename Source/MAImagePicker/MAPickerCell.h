//
//  MAPickerCell.h
//

#import <UIKit/UIKit.h>

@interface MAPickerCell : UICollectionViewCell

// item: [type (MAMediaType), item (PHAsset or ALAsset), img, ... ]
- (void)setItem: (NSArray*)item isSel: (BOOL)isSel;
// reload image only
- (void)setItem: (NSArray*)item;

@end

