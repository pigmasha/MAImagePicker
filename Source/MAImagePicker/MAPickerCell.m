//
//  MAPickerCell.m
//

#import "MAPickerCell.h"
#import "MAPickerConstants.h"
#import "MAPickerController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#define PICK_DUR_Y 6
#define PICK_DUR_R 5

//=================================================================================

@interface MAPickerCell ()
{
    UIImageView* _v;
    UIImageView* _video;
    UILabel* _dur;
    UIImageView* _chk;
    UIView* _bg;
}
@end

//=================================================================================

@implementation MAPickerCell

//---------------------------------------------------------------------------------
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame: frame])
    {
        _v = [[UIImageView alloc] initWithFrame: self.contentView.bounds];
        _v.autoresizingMask = SZ(Width) | SZ(Height);
        _v.contentMode = UIViewContentModeScaleAspectFill;
        _v.clipsToBounds = YES;
        [self.contentView addSubview: _v];
        [_v release];
        
        _bg = [[UIView alloc] initWithFrame: self.contentView.bounds];
        _bg.autoresizingMask = SZ(Width) | SZ(Height);
        [self.contentView addSubview: _bg];
        [_bg release];
        
        UIImage* img = [UIImage imageNamed: @"button_check"];
        _chk = [[UIImageView alloc] initWithFrame: CGRectMake([MAPickerController thumbSz] - img.size.width - 5, [MAPickerController thumbSz] - img.size.height - 5, img.size.width, img.size.height)];
        _chk.autoresizingMask = SZ_M(Top) | SZ_M(Left);
        [self.contentView addSubview: _chk];
        [_chk release];
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)dealloc
{
    [_dur release];
    [super dealloc];
}

//---------------------------------------------------------------------------------
// item: [type (MAMediaType), item (PHAsset or ALAsset), img, ... ]
//---------------------------------------------------------------------------------
- (void)setItem: (NSArray*)item isSel: (BOOL)isSel
{
    _v.image = [item objectAtIndex: 2];
    _bg.backgroundColor = (isSel) ? [UIColor colorWithWhite: 1 alpha: 0.5] : [UIColor clearColor];
    _chk.image = [UIImage imageNamed: (isSel) ? @"button_check_a" : @"button_check"];
    
    int t = [[item firstObject] intValue];
    id a = [item objectAtIndex: 1];
    
    [self setIsVideo: t == MAMediaVideoAL || t == MAMediaVideoPH
                 dur: (t == MAMediaPhotoPH || t == MAMediaVideoPH) ? ((PHAsset*)a).duration : [[a valueForProperty: ALAssetPropertyDuration] intValue]];
}

//---------------------------------------------------------------------------------
// reload image only
//---------------------------------------------------------------------------------
- (void)setItem: (NSArray*)item
{
    _v.image = [item objectAtIndex: 2];
}

//---------------------------------------------------------------------------------
- (void)setIsVideo: (BOOL)isVideo dur: (int)d
{
    if (isVideo)
    {
        if (!_dur)
        {
            _dur = [[UILabel alloc] init];
            _dur.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.5];
            _dur.font = [UIFont systemFontOfSize: 12];
            _dur.textColor = [UIColor whiteColor];
            _dur.autoresizingMask = SZ(Width);
        }
        _dur.frame = CGRectMake(0, 0, self.contentView.bounds.size.width, 20);
        NSString* dur = [[NSString alloc] initWithFormat: @" %02d:%02d", d / 60, d % 60];
        _dur.text = dur;
        [dur release];
        if (![_dur superview]) [self.contentView addSubview: _dur];
        
        if (!_video)
        {
            UIImage* img = [UIImage imageNamed: @"icon_video"];
            _video = [[UIImageView alloc] initWithImage: img];
            _video.frame = CGRectMake([MAPickerController thumbSz] - img.size.width - PICK_DUR_R, PICK_DUR_Y, img.size.width, img.size.height);
            _video.autoresizingMask = SZ_M(Right);
            [self.contentView addSubview: _video];
            [_video release];
        } else {
            _video.image = [UIImage imageNamed: @"icon_video"];
        }
    } else {
        if (_video) _video.image = nil;
        [_dur removeFromSuperview];
    }
}

@end
