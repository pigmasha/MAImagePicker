//
//  MAPickerTmbView.m
//

#import "MAPickerTmbView.h"
#import "MAPickerController.h"
#import "MAPickerListController.h"
#import "MAPickerConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define PICKT_DUR_R 5
#define PICKT_DUR_Y 6
#define PICKT_MAX_H 35

@interface MAPickerTmbView ()
{
    // _items = [type (MAMediaType), item (PHAsset or ALAsset), img, assetURL, UIImageView(thumb), UIImageView(checkbox)]
    NSMutableArray* _items;
    int _sz;
    int _p;
    
    ALAssetsGroup* _album;
    MAPickerListController5* _vc;
    UILabel* _errMax;
    NSTimer* _errTimer;
}
@end

//=================================================================================

@interface MAPickerTmb : UIImageView
@end

//=================================================================================

@implementation MAPickerTmbView

//---------------------------------------------------------------------------------
- (instancetype)initWithFrame: (CGRect)frame album: (ALAssetsGroup*)album vc: (MAPickerListController5*)vc
{
    if (self = [super initWithFrame: frame])
    {
        self.backgroundColor = [UIColor whiteColor];
        _items = [[NSMutableArray alloc] init];
        _sz = [UIScreen mainScreen].bounds.size.width / 4 - 1;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) _sz = PICKER_W / 4 - 1;
        _p = 4;
        
        _album = album;
        [self loadItems];
        [self posImgs];
        _vc = vc;
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)loadItems
{
    ALAssetsGroupEnumerationResultsBlock blockEn = ^(ALAsset *result, NSUInteger index, BOOL *stop)
    {
        if (result)
        {
            NSMutableArray* objects = [[MAPickerController sharedInstance] selObjects];
            NSString* filename = [[result defaultRepresentation] filename];
            
            UIImage* img = [[UIImage alloc] initWithCGImage: [result thumbnail]];
            UIImageView* v = [[MAPickerTmb alloc] initWithImage: img];
            v.userInteractionEnabled = YES;
            
            int type = ([[result valueForProperty: ALAssetPropertyType] isEqualToString: ALAssetTypeVideo]) ? MAMediaVideoAL : MAMediaPhotoAL;
            if (type == MAMediaVideoAL) [MAPickerTmbView addVideoLabel: v sz: _sz dur: [[result valueForProperty: ALAssetPropertyDuration] intValue]];
            
            UIImage* i = [UIImage imageNamed: ([objects containsObject: filename]) ? @"button_check_a" : @"button_check"];
            UIImageView* v2 = [[UIImageView alloc] initWithImage: i];
            v2.frame = CGRectMake(_sz - i.size.width - 5, _sz - i.size.height - 5, i.size.width, i.size.height);
            [v addSubview: v2];
            [v2 release];
            
            [self addSubview: v];
            
            NSNumber* typeN = [[NSNumber alloc] initWithInt: type];
            NSMutableArray* item = [[NSMutableArray alloc] initWithObjects: typeN, result, img, filename, v, v2, nil];
            [img release];
            [typeN release];
            [v release];
            
            [_items addObject: item];
            [item release];
        }
    };
    
    [_album enumerateAssetsUsingBlock: blockEn];
}

//---------------------------------------------------------------------------------
- (void)onImg: (id)sender
{
    for (NSMutableArray* item2 in _items)
    {
        if ([item2 objectAtIndex: 4] == sender)
        {
            NSMutableArray* objects = [[MAPickerController sharedInstance] selObjects];
            NSMutableArray* items   = [[MAPickerController sharedInstance] selItems];
            
            id item = [item2 objectAtIndex: 3];
            NSUInteger i = [objects indexOfObject: item];
            if (i == NSNotFound)
            {
                if ([[MAPickerController sharedInstance] maxSel] && [objects count] >= [[MAPickerController sharedInstance] maxSel])
                {
                    if (!_errMax)
                    {
                        ADD_LABEL(_errMax, self, UITextAlignmentCenter, 15, NO, [UIColor blackColor], SZ(Width), 0, -PICKT_MAX_H, self.bounds.size.width, PICKT_MAX_H);
                        NSString* str = [[NSString alloc] initWithFormat: @"You can choose up to %d photos", [[MAPickerController sharedInstance] maxSel]];
                        _errMax.text = str;
                        [str release];
                        _errMax.backgroundColor = [UIColor colorWithRed: 1 green: 0.4 blue: 0.2 alpha: 1];
                        _errMax.textColor = [UIColor whiteColor];
                        
                        [UIView animateWithDuration: 0.5
                                              delay: 0
                                            options: UIViewAnimationOptionCurveEaseIn
                                         animations: ^{ _errMax.frame = CGRectMake(0, 0, self.bounds.size.width, PICKT_MAX_H); }
                                         completion: ^(BOOL finished){ }];
                    }
                    [_errTimer invalidate];
                    [_errTimer release];
                    
                    NSDate* d = [[NSDate alloc] initWithTimeIntervalSinceNow: 2];
                    _errTimer = [[NSTimer alloc] initWithFireDate: d interval: 2 target: self selector: @selector(errMaxTimer) userInfo: nil repeats: NO];
                    [d release];
                    [[NSRunLoop currentRunLoop] addTimer: _errTimer forMode: NSDefaultRunLoopMode];
                    return;
                }
                [objects addObject: item];
                [items   addObject: item2];
            } else {
                [objects removeObjectAtIndex: i];
                [items   removeObjectAtIndex: i];
            }
            [_vc reloadDone];
            
            [[item2 objectAtIndex: 5] removeFromSuperview];
            
            UIImage* img = [UIImage imageNamed: (i == NSNotFound) ? @"button_check_a" : @"button_check"];
            UIImageView* v2 = [[UIImageView alloc] initWithImage: img];
            v2.frame = CGRectMake(_sz - img.size.width - 5, _sz - img.size.height - 5, img.size.width, img.size.height);
            [[item2 objectAtIndex: 4] addSubview: v2];
            [item2 replaceObjectAtIndex: 5 withObject: v2];
            [v2 release];
            
            break;
        }
    }
}

//---------------------------------------------------------------------------------
- (void)errMaxTimer
{
    UIView* v = _errMax;
    _errMax = nil;
    [UIView animateWithDuration: 0.5
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations: ^{ v.frame = CGRectMake(0, -PICKT_MAX_H, self.bounds.size.width, PICKT_MAX_H); }
                     completion: ^(BOOL finished){ [v removeFromSuperview]; }];
}

//---------------------------------------------------------------------------------
+ (void)addVideoLabel: (UIView*)view sz: (int)sz dur: (int)d
{
    UILabel* dur;
    ADD_LABEL(dur, view, UITextAlignmentLeft, 12, NO, [UIColor whiteColor], 0, 0, 0, sz, 20);
    dur.backgroundColor = [UIColor colorWithWhite: 0 alpha: 0.5];
    NSString* s = [[NSString alloc] initWithFormat: @" %02d:%02d", d / 60, d % 60];
    dur.text = s;
    [s release];
    
    UIImage* i = [UIImage imageNamed: @"icon_video"];
    UIImageView* v2 = [[UIImageView alloc] initWithImage: i];
    v2.frame = CGRectMake(sz - i.size.width - PICKT_DUR_R, PICKT_DUR_Y, i.size.width, i.size.height);
    [view addSubview: v2];
    [v2 release];
}

//---------------------------------------------------------------------------------
- (void)setFrame:(CGRect)frame
{
    [super setFrame: frame];
    [self posImgs];
}

//---------------------------------------------------------------------------------
- (void)posImgs
{
    CGRect r;
    r.origin.x = 0;
    r.origin.y = 0;
    r.size.width = _sz;
    r.size.height = _sz;
    
    int w = self.bounds.size.width;
    
    for (NSArray* item in _items)
    {
        ((UIView*)[item objectAtIndex: _p]).frame = r;
        r.origin.x += _sz + 2;
        if (r.origin.x + _sz > w + 2)
        {
            r.origin.x = 0;
            r.origin.y += _sz + 2;
        }
    }
    if (r.origin.x) r.origin.y += _sz + 2;
    self.contentSize = CGSizeMake(w, r.origin.y);
}

@end

//=================================================================================

@implementation MAPickerTmb

//---------------------------------------------------------------------------------
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded: touches withEvent: event];
    [(MAPickerTmbView*)[self superview] onImg: self];
}

@end

