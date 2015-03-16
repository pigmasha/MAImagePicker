//
//  MAImageCell.h
//

#import <UIKit/UIKit.h>

#define IMG_MAX_W 240
#define IMG_MAX_H 160
#define IMG_MARGIN 5

@interface MAImageCell : UITableViewCell

+ (NSString *)identifier;
- (void)setItem: (NSArray*)item;

@end
