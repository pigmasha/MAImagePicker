//
//  MAPickerAlbCell.m
//

#import "MAPickerAlbCell.h"
#import "MAPickerConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define PICKA_IMG_X 9
#define PICKA_IMG_SZ 68
#define PICKA_NAME_FONT_SZ 15
#define PICKA_NAME_X 96
#define PICKA_NAME_Y 10
#define PICKA_NAME_H 45
#define PICKA_CNT_FONT_SZ 12
#define PICKA_CNT_Y 45
#define PICKA_CNT_H 20
#define PICKA_DUR_Y 6
#define PICKA_DUR_R 5

@interface MAPickerAlbCell ()
{
    UIImageView* _img;
    UILabel* _name;
    UILabel* _cnt;
}
@end

//=================================================================================

@implementation MAPickerAlbCell

//---------------------------------------------------------------------------------
+ (NSString*)identifier
{
    static NSString* _s_identifier = @"A3";
    return _s_identifier;
}

//---------------------------------------------------------------------------------
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle: style reuseIdentifier: reuseIdentifier])
    {
        CGRect r = self.bounds;
        
        _img = [[UIImageView alloc] initWithFrame: CGRectMake(PICKA_IMG_X, PICKA_IMG_X, PICKA_IMG_SZ, PICKA_IMG_SZ)];
        [self.contentView addSubview: _img];
        [_img release];
        
        ADD_LABEL(_name, self.contentView, UITextAlignmentLeft, PICKA_NAME_FONT_SZ, NO, [UIColor blackColor], SZ(Width), PICKA_NAME_X, PICKA_NAME_Y, r.size.width - PICKA_NAME_X - 10, PICKA_NAME_H);
        ADD_LABEL(_cnt,  self.contentView, UITextAlignmentLeft, PICKA_CNT_FONT_SZ, NO, [UIColor blackColor], SZ(Width), PICKA_NAME_X, PICKA_CNT_Y, r.size.width - PICKA_NAME_X - 10, PICKA_CNT_H);
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)setItem: (ALAssetsGroup*)item
{
    UIImage* posterImage = [UIImage imageWithCGImage: [item posterImage]];
    _img.image = posterImage;
    _name.text = [item valueForProperty: ALAssetsGroupPropertyName];
    NSString* str = [[NSString alloc] initWithFormat: @"%d", (int)[item numberOfAssets]];
    _cnt.text = str;
    [str release];
}

@end

//=================================================================================

@interface MAPickerAlb2Cell ()
{
    UIImageView* _img;
    UIImageView* _img2;
    UIImageView* _img3;
    UIImageView* _video; // video icon
    UILabel* _name;
    UILabel* _cnt;
}
@end

//=================================================================================

@implementation MAPickerAlb2Cell

//---------------------------------------------------------------------------------
+ (NSString*)identifier
{
    static NSString* _s_identifier = @"A4";
    return _s_identifier;
}

//---------------------------------------------------------------------------------
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle: style reuseIdentifier: reuseIdentifier])
    {
        CGRect r = self.bounds;
        
        _img3 = [[UIImageView alloc] initWithFrame: CGRectMake(PICKA_IMG_X + 4, PICKA_IMG_X - 4, PICKA_IMG_SZ - 8, PICKA_IMG_SZ - 8)];
        _img3.contentMode = UIViewContentModeScaleAspectFill;
        [MAPickerAlb2Cell addCrop: CGRectMake(0, 0, 60, 1.5) toView: _img3];
        [self.contentView addSubview: _img3];
        [_img3 release];
        
        _img2 = [[UIImageView alloc] initWithFrame: CGRectMake(PICKA_IMG_X + 2, PICKA_IMG_X - 2, PICKA_IMG_SZ - 4, PICKA_IMG_SZ - 4)];
        _img2.contentMode = UIViewContentModeScaleAspectFill;
        [MAPickerAlb2Cell addCrop: CGRectMake(0, 0, 64, 1.5) toView: _img2];
        [self.contentView addSubview: _img2];
        [_img2 release];
        
        _img = [[UIImageView alloc] initWithFrame: CGRectMake(PICKA_IMG_X, PICKA_IMG_X, PICKA_IMG_SZ, PICKA_IMG_SZ)];
        _img.contentMode = UIViewContentModeScaleAspectFill;
        _img.clipsToBounds = YES;
        [self.contentView addSubview: _img];
        [_img release];
        
        ADD_LABEL(_name, self.contentView, UITextAlignmentLeft, PICKA_NAME_FONT_SZ, NO, [UIColor blackColor], SZ(Width), PICKA_NAME_X, PICKA_NAME_Y, r.size.width - PICKA_NAME_X - 10, PICKA_NAME_H);
        ADD_LABEL(_cnt,  self.contentView, UITextAlignmentLeft, PICKA_CNT_FONT_SZ, NO, [UIColor blackColor], SZ(Width), PICKA_NAME_X, PICKA_CNT_Y, r.size.width - PICKA_NAME_X - 10, PICKA_CNT_H);
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)setItem: (NSArray*)item
{
    _name.text = [item firstObject];
    _cnt.text   = [item objectAtIndex: 1];
    _img.image  = [item objectAtIndex: 4];
    _img2.image = [item objectAtIndex: 5];
    _img3.image = [item objectAtIndex: 6];
    
    if ([[item objectAtIndex: 3] boolValue])
    {
        if (!_video)
        {
            UIImage* img = [UIImage imageNamed: @"icon_video"];
            _video = [[UIImageView alloc] initWithFrame: CGRectMake(PICKA_IMG_X + PICKA_IMG_SZ - img.size.width - PICKA_DUR_R, PICKA_IMG_X + PICKA_DUR_Y, img.size.width, img.size.height)];
            [self addSubview: _video];
            [_video release];
        }
        _video.image = [UIImage imageNamed: @"icon_video"];
    } else {
        if (_video) _video.image = nil;
    }
}

//---------------------------------------------------------------------------------
+ (void)addCrop: (CGRect)r toView: (UIView*)v
{
    CAShapeLayer* maskLayer = [[CAShapeLayer alloc] init];
    
    CGPathRef path = CGPathCreateWithRect(r, NULL);
    maskLayer.path = path;
    CGPathRelease(path);
    
    v.layer.mask = maskLayer;
    [maskLayer release];
}

@end
