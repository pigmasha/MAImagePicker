//
//  MAImageCell.m
//

#import "MAImageCell.h"

#define IMG_DUR_H 20
#define IMG_DUR_Y 6

@interface MAImageCell ()
{
    UIImageView* _img;
    UIImageView* _video;
    UILabel* _dur;
}
@end

//=================================================================================

@implementation MAImageCell

//---------------------------------------------------------------------------------
+ (NSString *)identifier
{
    static NSString* _s_identifier = @"I1";
    return _s_identifier;
}

//---------------------------------------------------------------------------------
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle: style reuseIdentifier: reuseIdentifier])
    {
        _img = [[UIImageView alloc] init];
        [self.contentView addSubview: _img];
        [_img release];
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)setItem: (NSArray*)item
{
    _img.image = ([item count] > 4) ? [item objectAtIndex: 5] : [UIImage imageNamed: @"photo_thumb"];
    
    int w = [[item objectAtIndex: 2] intValue];
    _img.frame = CGRectMake(5, 5, w, [[item objectAtIndex: 3] intValue]);
    
    int d = [[item objectAtIndex: 4] intValue];
    
    if (d < 0)
    {
        [_video removeFromSuperview];
        _video = nil;
        [_dur removeFromSuperview];
        _dur = nil;
        return;
    }
    
    if (!_dur)
    {
        _dur = [[UILabel alloc] init];
        _dur.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.5];
        _dur.font = [UIFont systemFontOfSize: 12];
        _dur.textColor = [UIColor whiteColor];
        [self.contentView addSubview: _dur];
        [_dur release];
    }
    _dur.frame = CGRectMake(IMG_MARGIN, IMG_MARGIN, w, IMG_DUR_H);
    NSString* dur = [[NSString alloc] initWithFormat: @" %02d:%02d", d / 60, d % 60];
    _dur.text = dur;
    [dur release];
    
    UIImage* img = [UIImage imageNamed: @"icon_video"];
    if (!_video)
    {
        _video = [[UIImageView alloc] initWithImage: img];
        [self.contentView addSubview: _video];
        [_video release];
    }
    _video.frame = CGRectMake(IMG_MARGIN + w - img.size.width - IMG_MARGIN, IMG_MARGIN + IMG_DUR_Y, img.size.width, img.size.height);
}

//---------------------------------------------------------------------------------
- (UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}

@end
