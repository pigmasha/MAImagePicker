//
//  MAPickerAlbCell.h
//

#import <UIKit/UIKit.h>

#define PICKA_ROW_H 86

@class ALAssetsGroup;

@interface MAPickerAlbCell : UITableViewCell 

+ (NSString*)identifier;
- (void)setItem: (ALAssetsGroup*)item;

@end

//=================================================================================

@interface MAPickerAlb2Cell : UITableViewCell

+ (NSString*)identifier;
- (void)setItem: (NSArray*)item;

@end
