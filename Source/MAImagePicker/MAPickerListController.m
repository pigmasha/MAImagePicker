//
//  MAPickerListController.m
//

#import "MAPickerListController.h"
#import "MAPickerCell.h"
#import "MAPickerController.h"
#import "MAPickerTmbView.h"
#import "MAPickerConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#define PICK_MAX_H 35

@interface MAPickerListController ()
{
    ALAssetsGroup* _album;
    NSArray* _item;
    NSMutableArray* _items; // [type (MAMediaType), item (PHAsset or ALAsset), img, assetURL]
    BOOL _didApp;
    UILabel* _errMax;
    NSTimer* _errTimer;
    BOOL _scrolled;
    BOOL _isDone;
}
@end

//=================================================================================

@implementation MAPickerListController

//---------------------------------------------------------------------------------
// item is ALAssetsGroup or NSArray
//---------------------------------------------------------------------------------
- (instancetype)initWithItem: (id)item isPh: (BOOL)isPh
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake([MAPickerController thumbSz], [MAPickerController thumbSz]);
    layout.minimumInteritemSpacing = 2;
    layout.minimumLineSpacing = 2;
    if (self = [super initWithCollectionViewLayout: layout])
    {
        if (isPh)
        {
            _item = [item retain];
        } else {
            _album = [item retain];
        }
    }
    [layout release];
    return self;
}

//---------------------------------------------------------------------------------
- (CGSize)contentSizeForViewInPopover
{
    return CGSizeMake(PICKER_W, PICKER_H);
}

#define PICK_CELL_ID @"P6"

//---------------------------------------------------------------------------------
- (void)loadView
{
    [super loadView];
    self.title = (_album) ? [_album valueForProperty: ALAssetsGroupPropertyName] : [_item firstObject];
    
    [self.collectionView registerClass: [MAPickerCell class] forCellWithReuseIdentifier: PICK_CELL_ID];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    _items = [[NSMutableArray alloc] init];
    
    if (_album)
    {
        ALAssetsGroupEnumerationResultsBlock blockEn = ^(ALAsset *result, NSUInteger index, BOOL *stop)
        {
            if (result)
            {
                UIImage* img = [[UIImage alloc] initWithCGImage: [result thumbnail]];
                NSNumber* typeN = [[NSNumber alloc] initWithInt: ([[result valueForProperty: ALAssetPropertyType] isEqualToString: ALAssetTypeVideo]) ? MAMediaVideoAL : MAMediaPhotoAL];
                NSArray* item = [[NSArray alloc] initWithObjects: typeN, result, img, [result valueForProperty: ALAssetPropertyAssetURL], nil];
                [typeN release];
                [img release];
                
                [_items addObject: item];
                [item release];
            }
        };
        
        [_album enumerateAssetsUsingBlock: blockEn];
    } else {
        UIImage* img = [UIImage imageNamed: @"photo_thumb"];
        for (PHAsset* a in [_item objectAtIndex: 2])
        {
            NSNumber* typeN = [[NSNumber alloc] initWithInt: (a.mediaType == PHAssetMediaTypeVideo) ? MAMediaVideoPH : MAMediaPhotoPH];
            NSMutableArray* item = [[NSMutableArray alloc] initWithObjects: typeN, a, img, nil];
            [typeN release];
            [_items addObject: item];
            [item release];
        }
    }
}

//---------------------------------------------------------------------------------
- (void)dealloc
{
    [_album release];
    [_item  release];
    [_items release];
    [super dealloc];
}

//---------------------------------------------------------------------------------
- (void)imageLoaded: (UIImage*)img idx: (NSUInteger)idx
{
    if (!img) return;
    
    NSMutableArray* item = [_items objectAtIndex: idx];
    [item replaceObjectAtIndex: 2 withObject: img];
    [item addObject: [item lastObject]];
    
    NSUInteger i1[] = { 0, idx };
    NSIndexPath* x = [[NSIndexPath alloc] initWithIndexes: i1 length: 2];
    MAPickerCell* cell = (MAPickerCell*)[self.collectionView cellForItemAtIndexPath: x];
    [cell setItem: item];
    [x release];
}

//---------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isDone = ([[[MAPickerController sharedInstance] selItems] count] > 0);
    UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: (_isDone) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                                                        target: [MAPickerController sharedInstance] action: @selector(onOk)];
	self.navigationItem.rightBarButtonItem = bt;
    [bt release];
    
    if ([_items count] && !_scrolled) [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem: [_items count] - 1 inSection: 0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

//---------------------------------------------------------------------------------
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    _didApp = YES;
    if ([_items count] && !_scrolled) [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem: [_items count] - 1 inSection: 0] atScrollPosition: UICollectionViewScrollPositionTop animated:NO];
    _scrolled = YES;
}

//---------------------------------------------------------------------------------
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!_didApp && [_items count])
    {
        NSUInteger i1[] = { 0, [_items count] - 1 };
        NSIndexPath* i2 = [[NSIndexPath alloc] initWithIndexes: i1 length: 2];
        [self.collectionView scrollToItemAtIndexPath: i2 atScrollPosition: UICollectionViewScrollPositionTop animated: NO];
        [i2 release];
    }
}

//---------------------------------------------------------------------------------
// <UICollectionViewDataSource>
//---------------------------------------------------------------------------------
- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [_items count];
}

//---------------------------------------------------------------------------------
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MAPickerCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier: PICK_CELL_ID forIndexPath: indexPath];
    NSArray* item = [_items objectAtIndex: indexPath.row];
    
    int s = [MAPickerController thumbSz] * [[UIScreen mainScreen] scale];
    if (_item && [item count] < 4)
    {
        NSUInteger n = indexPath.row;
        [[[MAPickerController sharedInstance] imgCache] requestImageForAsset: [item objectAtIndex: 1] targetSize: CGSizeMake(s, s)
                                           contentMode: PHImageContentModeAspectFill options: nil
                                         resultHandler: ^(UIImage *result, NSDictionary *info)
         {
             [self imageLoaded: result idx: n];
         }];
    }
    [cell setItem: item isSel: [[[MAPickerController sharedInstance] selObjects] containsObject: (_album) ? [item lastObject] : [item objectAtIndex: 1]]];
    return cell;
}

//---------------------------------------------------------------------------------
// <UICollectionViewDelegate>
//---------------------------------------------------------------------------------
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray* objects = [[MAPickerController sharedInstance] selObjects];
    NSMutableArray* items   = [[MAPickerController sharedInstance] selItems];
    
    NSArray* item2 = [_items objectAtIndex: indexPath.row];
    id item = (_album) ? [item2 lastObject] : [item2 objectAtIndex: 1];
    
    NSUInteger i = [objects indexOfObject: item];
    if (i == NSNotFound)
    {
        if ([[MAPickerController sharedInstance] maxSel] && [objects count] >= [[MAPickerController sharedInstance] maxSel])
        {
            if (!_errMax)
            {
                ADD_LABEL(_errMax, self.view, UITextAlignmentCenter, 15, NO, [UIColor blackColor], SZ(Width), 0, self.collectionView.contentInset.top - PICK_MAX_H, self.view.bounds.size.width, PICK_MAX_H);
                NSString* str = [[NSString alloc] initWithFormat: @"You can choose up to %d photos", [[MAPickerController sharedInstance] maxSel]];
                _errMax.text = str;
                [str release];
                _errMax.backgroundColor = [UIColor colorWithRed: 1 green: 0.4 blue: 0.2 alpha: 1];
                _errMax.textColor = [UIColor whiteColor];
                
                [UIView animateWithDuration: 0.5
                                      delay: 0
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations: ^{ _errMax.frame = CGRectMake(0, self.collectionView.contentInset.top, self.view.bounds.size.width, PICK_MAX_H); }
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
        
        if (_isDone != YES)
        {
            _isDone = YES;
            UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: (_isDone) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                                                                target: [MAPickerController sharedInstance] action: @selector(onOk)];
            self.navigationItem.rightBarButtonItem = bt;
            [bt release];
        }
    } else {
        [objects removeObjectAtIndex: i];
        [items   removeObjectAtIndex: i];
        
        BOOL isDone = ([objects count] > 0);
        if (_isDone != isDone)
        {
            _isDone = isDone;
            UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: (_isDone) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                                                                target: [MAPickerController sharedInstance] action: @selector(onOk)];
            self.navigationItem.rightBarButtonItem = bt;
            [bt release];
        }
    }
    NSArray* idx = [[NSArray alloc] initWithObjects: indexPath, nil];
    [self.collectionView reloadItemsAtIndexPaths: idx];
    [idx release];
}

//---------------------------------------------------------------------------------
- (void)errMaxTimer
{
    UIView* v = _errMax;
    _errMax = nil;
    [UIView animateWithDuration: 0.5
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations: ^{ v.frame = CGRectMake(0, self.collectionView.contentInset.top - PICK_MAX_H, self.view.bounds.size.width, PICK_MAX_H); }
                     completion: ^(BOOL finished){ [v removeFromSuperview]; }];
}

@end

//=================================================================================

@interface MAPickerListController5 ()
{
    ALAssetsGroup* _album;
    NSMutableArray* _items;
    BOOL _isDone;
}
@end

//=================================================================================

@implementation MAPickerListController5

//---------------------------------------------------------------------------------
- (instancetype)initWithAlbum: (ALAssetsGroup*)item
{
    if (self = [super initWithNibName: nil bundle: nil])
    {
        _album = [item retain];
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)dealloc
{
    [_album release];
    [_items release];
    [super dealloc];
}

//---------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _isDone = ([[[MAPickerController sharedInstance] selObjects] count] > 0);
    UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: (_isDone) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                                                        target: [MAPickerController sharedInstance] action: @selector(onOk)];
	self.navigationItem.rightBarButtonItem = bt;
    [bt release];
}

//---------------------------------------------------------------------------------
- (void)reloadDone
{
    BOOL isDone = ([[[MAPickerController sharedInstance] selObjects] count] > 0);
    
    if (_isDone != isDone)
    {
        _isDone = isDone;
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: (_isDone) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemCancel
                                                                            target: [MAPickerController sharedInstance] action: @selector(onOk)];
        self.navigationItem.rightBarButtonItem = bt;
        [bt release];
    }
}

//---------------------------------------------------------------------------------
- (void)loadView
{
    [super loadView];
    MAPickerTmbView* v = [[MAPickerTmbView alloc] initWithFrame: self.view.bounds album: _album vc: self];
    v.autoresizingMask = SZ(Width) | SZ(Height);
    [self.view addSubview: v];
    [v release];
}

//---------------------------------------------------------------------------------
- (CGSize)contentSizeForViewInPopover
{
    return CGSizeMake(PICKER_W, PICKER_H);
}

@end
