//
//  MAPickerController.m
//

#import "MAPickerController.h"
#import "MAPickerAlbCell.h"
#import "MAPickerListController.h"
#import "MAPickerCell.h"
#import "MAPickerConstants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface MAPickerController ()
{
    // array of selected objects -- check if object selected by searching in this array
    NSMutableArray* _selObjects;
    NSMutableArray* _selItems;
    
    NSMutableArray* _items; // [title, cnt_str, photos, isVideo, img1, img2, img3]
    MAPhotoAccess _access;
    id<MAPickerDelegate> _d;
    BOOL _isPhAssets;
    int _maxSel;
    
    ALAssetsLibrary* _mediaLib;
    PHCachingImageManager* _imgCache;
}
@end

//=================================================================================

@implementation MAPickerController

static MAPickerController* _s_inst = nil;

//---------------------------------------------------------------------------------
+ (instancetype)sharedInstance
{
    return _s_inst;
}

//---------------------------------------------------------------------------------
- (instancetype)initWithDelegate: (id<MAPickerDelegate>)delegate maxSel: (int)maxSel
{
    if (self = [super initWithStyle: UITableViewStylePlain])
    {
        _d = delegate;
        _maxSel = maxSel;
        _s_inst = self;
    }
    return self;
}

//---------------------------------------------------------------------------------
- (void)dealloc
{
    if (_s_inst == self) _s_inst = nil;
    [_items      release];
    [_selObjects release];
    [_selItems   release];
    [_mediaLib   release];
    [_imgCache   release];
    [super dealloc];
}

//---------------------------------------------------------------------------------
- (CGSize)contentSizeForViewInPopover
{
    return CGSizeMake(PICKER_W, PICKER_H);
}

//---------------------------------------------------------------------------------
- (void)onCancel
{
    if (_s_inst == self) _s_inst = nil;
    [_d pickerOnOk: nil];
}

//---------------------------------------------------------------------------------
- (void)onOk
{
    if (_s_inst == self) _s_inst = nil;
    [_d pickerOnOk: ([_selItems count]) ? _selItems : nil];
}

//---------------------------------------------------------------------------------
- (NSMutableArray*)selObjects
{
    return _selObjects;
}

//---------------------------------------------------------------------------------
- (NSMutableArray*)selItems
{
    return _selItems;
}

//---------------------------------------------------------------------------------
- (int)maxSel
{
    return _maxSel;
}

//---------------------------------------------------------------------------------
- (PHCachingImageManager*)imgCache
{
    return _imgCache;
}

//---------------------------------------------------------------------------------
- (void)loadView
{
    [super loadView];
    self.title = @"Albums";
    
    _items      = [[NSMutableArray alloc] init];
    _selObjects = [[NSMutableArray alloc] init];
    _selItems   = [[NSMutableArray alloc] init];
    
    _access = [MAPickerController photosAccess];
    
    if ([PHFetchResult class])
    {
        _imgCache = [[PHCachingImageManager alloc] init];
        _isPhAssets = YES;
        if (_access == MAPhotoMiss)
        {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status)
            {
                [self performSelectorOnMainThread: @selector(loadPhAssets) withObject: nil waitUntilDone: NO];
            }];
        } else {
            [self loadPhAssets];
        }
    } else {
        _mediaLib = [[ALAssetsLibrary alloc] init];
        
        ALAssetsLibraryAccessFailureBlock blockErr = ^(NSError *error)
        {
            _access = ([error code] == ALAssetsLibraryAccessUserDeniedError || [error code] == ALAssetsLibraryAccessGloballyDeniedError) ? MAPhotoNo : MAPhotoNo2;
            [self.tableView reloadData];
        };
        
        ALAssetsLibraryGroupsEnumerationResultsBlock blockEn = ^(ALAssetsGroup *group, BOOL *stop)
        {
            _access = MAPhotoOK;
            if ([group numberOfAssets] > 0)
            {
                if ([[group valueForProperty: ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos)
                {
                    [_items insertObject: group atIndex: 0];
                } else {
                    [_items addObject: group];
                }
            } else {
                [self performSelectorOnMainThread: @selector(itemsLoaded) withObject: nil waitUntilDone: NO];
            }
        };
        
        [_mediaLib enumerateGroupsWithTypes: ALAssetsGroupAll usingBlock: blockEn failureBlock: blockErr];
    }
}

//---------------------------------------------------------------------------------
// load (Photos.framework)
//---------------------------------------------------------------------------------
- (void)loadPhAssets
{
    _access = [MAPickerController photosAccess];
    
    if (_access != MAPhotoOK)
    {
        [self.tableView reloadData];
        return;
    }
    
    UIImage* img1 = [UIImage imageNamed: @"photo_thumb"];
    UIImage* img2 = [UIImage imageNamed: @"pixel_transp"];
    
    for (int i = 0; i < 4; i++)
    {
        PHFetchResult* items = (i < 3) ? [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype: (i == 0) ? PHAssetCollectionSubtypeSmartAlbumUserLibrary : ((i == 1) ? PHAssetCollectionSubtypeSmartAlbumFavorites : PHAssetCollectionSubtypeSmartAlbumVideos) options:nil] :
        [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        
        for (int j = 0; j < items.count; j++)
        {
            PHAssetCollection* coll = [items objectAtIndex: j];
            if (![coll isKindOfClass: [PHAssetCollection class]]) continue;
            
            PHFetchResult* photos = [PHAsset fetchAssetsInAssetCollection: coll options: nil];
            if (!photos.count) continue;
            
            NSString* str = [[NSString alloc] initWithFormat: @"%d", (int)photos.count];
            PHAsset* ph = [photos lastObject];
            NSNumber* isVideo = [[NSNumber alloc] initWithBool: ph.mediaType == PHAssetMediaTypeVideo];
            NSMutableArray* item = [[NSMutableArray alloc] initWithObjects: [coll localizedTitle], str, photos, isVideo, img1,
                                    (photos.count > 1) ? img1 : img2, (photos.count > 2) ? img1 : img2, nil];
            [str release];
            [isVideo release];
            [_items addObject: item];
            [item release];
        }
    }
    [self.tableView reloadData];
    if ([_items count]) [self selectRow: 0 animated: NO];
    
    int s = [MAPickerController thumbSz] * [[UIScreen mainScreen] scale];
    CGSize sz = CGSizeMake(s, s);
    for (int i = 0; i < [_items count]; i++)
    {
        NSArray* item = [_items objectAtIndex: i];
        PHFetchResult* photos = [item objectAtIndex: 2];
        [_imgCache requestImageForAsset: [photos lastObject] targetSize: sz contentMode: PHImageContentModeAspectFill options: nil
                          resultHandler: ^(UIImage *result, NSDictionary *info)
         {
             [self imageLoaded: result idx: i pos: 0];
         }];
        
        if (photos.count > 1)
        {
            [_imgCache requestImageForAsset: [photos objectAtIndex: photos.count - 2] targetSize: sz contentMode: PHImageContentModeAspectFill options: nil
                              resultHandler: ^(UIImage *result, NSDictionary *info)
             {
                 [self imageLoaded: result idx: i pos: 1];
             }];
        }
        if (photos.count > 2)
        {
            [_imgCache requestImageForAsset: [photos objectAtIndex: photos.count - 3] targetSize: sz contentMode: PHImageContentModeAspectFill options: nil
                              resultHandler: ^(UIImage *result, NSDictionary *info)
             {
                 [self imageLoaded: result idx: i pos: 2];
             }];
        }
    }
}

//---------------------------------------------------------------------------------
// calls after all items loaded (no Photos.framework)
//---------------------------------------------------------------------------------
- (void)itemsLoaded
{
    [self.tableView reloadData];
    if ([_items count]) [self selectRow: 0 animated: NO];
}

//---------------------------------------------------------------------------------
- (void)imageLoaded: (UIImage*)img idx: (NSUInteger)idx pos: (int)pos
{
    if (!img) return;
    
    NSMutableArray* item = [_items objectAtIndex: idx];
    [item replaceObjectAtIndex: 4 + pos withObject: img];
    
    NSUInteger i1[] = { 0, idx };
    NSIndexPath* x = [[NSIndexPath alloc] initWithIndexes: i1 length: 2];
    MAPickerAlb2Cell* cell = (MAPickerAlb2Cell*)[self.tableView cellForRowAtIndexPath: x];
    if ([cell isKindOfClass: [MAPickerAlb2Cell class]]) [cell setItem: item];
    [x release];
}

//---------------------------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad)
    {
        UIBarButtonItem* bt = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(onCancel)];
        self.navigationItem.rightBarButtonItem = bt;
        [bt release];
    }
}

//---------------------------------------------------------------------------------
- (void)selectRow: (NSInteger)row animated: (BOOL)animated
{
    UIViewController* vc = nil;
    if ([MAPickerController osVer] > 5)
    {
        vc = [[MAPickerListController alloc] initWithItem: [_items objectAtIndex: row] isPh: _isPhAssets];
    } else {
        vc = [[MAPickerListController5 alloc] initWithAlbum: [_items objectAtIndex: row]];
    }
    [self.navigationController pushViewController: vc animated: animated];
    [vc release];
}

//---------------------------------------------------------------------------------
// <UITableViewDataSource>
//---------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (_access == MAPhotoOK) ? [_items count] : 1;
}

#define MA_PICKER_CELL_ID @"P3"

//---------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_access != MAPhotoOK)
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: MA_PICKER_CELL_ID];
        
        if (!cell)
        {
            cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: MA_PICKER_CELL_ID] autorelease];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = (_access == MAPhotoNo) ? @"You declined access to photos" : ((_access == MAPhotoMiss) ? @"You cancel access to photos" : @"Read photos error");
        return cell;
    }
    
    if (_isPhAssets)
    {
        MAPickerAlb2Cell* cell = [tableView dequeueReusableCellWithIdentifier: [MAPickerAlb2Cell identifier]];
        if (!cell) cell = [[[MAPickerAlb2Cell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: [MAPickerAlb2Cell identifier]] autorelease];
        [cell setItem: [_items objectAtIndex: indexPath.row]];
        return cell;
    }
    
    MAPickerAlbCell* cell = [tableView dequeueReusableCellWithIdentifier: [MAPickerAlbCell identifier]];
    if (!cell) cell = [[[MAPickerAlbCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: [MAPickerAlbCell identifier]] autorelease];
    [cell setItem: [_items objectAtIndex: indexPath.row]];
    return cell;
}

//---------------------------------------------------------------------------------
// <UITableViewDelegate>
//---------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_access == MAPhotoOK)
    {
        [self selectRow: indexPath.row animated: YES];
        [tableView deselectRowAtIndexPath: indexPath animated: YES];
    }
}

//---------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return PICKA_ROW_H;
}

//---------------------------------------------------------------------------------
+ (MAPhotoAccess)photosAccess
{
    if ([self osVer] < 6) return MAPhotoOK;
    
    if ([PHFetchResult class])
    {
        PHAuthorizationStatus st = [PHPhotoLibrary authorizationStatus];
        switch (st)
        {
            case PHAuthorizationStatusAuthorized: return MAPhotoOK;
            case PHAuthorizationStatusNotDetermined: return MAPhotoMiss;
            case PHAuthorizationStatusDenied: return MAPhotoNo;
            default: break;
        }
        return MAPhotoNo2;
    }
    
    ALAuthorizationStatus st = [ALAssetsLibrary authorizationStatus];
    switch (st)
    {
        case ALAuthorizationStatusAuthorized: return MAPhotoOK;
        case ALAuthorizationStatusNotDetermined: return MAPhotoMiss;
        case ALAuthorizationStatusDenied: return MAPhotoNo;
        default: break;
    }
    return MAPhotoNo2;
}

//---------------------------------------------------------------------------------
+ (MAPhotoAccess)cameraAccess
{
    if ([self osVer] < 7 || ![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) return MAPhotoOK;
    
    AVAuthorizationStatus st = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (st)
    {
        case AVAuthorizationStatusAuthorized: return MAPhotoOK;
        case AVAuthorizationStatusNotDetermined: return MAPhotoMiss;
        case AVAuthorizationStatusDenied: return MAPhotoNo;
        default: break;
    }
    return MAPhotoNo2;
}

//---------------------------------------------------------------------------------
+ (int)osVer
{
    static int _s_n = 0;
    if (!_s_n)
    {
        NSString* v = [[UIDevice currentDevice] systemVersion];
        unichar c = ([v length]) ? [v characterAtIndex: 0] : 0;
        if (c > '0') _s_n = c - '0';
    }
    return _s_n;
}

//---------------------------------------------------------------------------------
+ (int)thumbSz
{
    static int _s_n = 0;
    if (!_s_n)
    {
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            _s_n = PICKER_W / 4 - 2;
        } else {
            _s_n = [UIScreen mainScreen].bounds.size.width / 4 - 2;
        }
    }
    return _s_n;
}

@end
