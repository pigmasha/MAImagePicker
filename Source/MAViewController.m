//
//  MAViewController.m
//

#import "MAViewController.h"
#import "MAPickerController.h"
#import "MAImageCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

@interface MAViewController ()<UIAlertViewDelegate, MAPickerDelegate, UIPopoverControllerDelegate>
{
    NSMutableArray* _items; // [type (MAMediaType), obj (ALAsset or PHAsset), width, height, duration (-1 for photos), UIImage (thumb)]
    UIPopoverController* _popover; // for iPads we need to display image picker in popover
    PHCachingImageManager* _imgCache;
}
@end

//=================================================================================

@implementation MAViewController

//---------------------------------------------------------------------------------
- (void)loadView
{
    [super loadView];
    self.title = @"MAImagePicker test";
    _items = [[NSMutableArray alloc] init];
    if ([self.tableView respondsToSelector: @selector(setSeparatorInset:)]) self.tableView.separatorInset = UIEdgeInsetsZero;
}

//---------------------------------------------------------------------------------
- (void)dealloc
{
    [_items    release];
    [_popover  release];
    [_imgCache release];
    
    [super dealloc];
}

//---------------------------------------------------------------------------------
// Show pre-permission dialog (our ask access before system access)
// You can skip this step, call askYes
//---------------------------------------------------------------------------------
- (void)askAccess
{
    MAPhotoAccess access = [MAPickerController photosAccess];
    
    switch (access)
    {
        case MAPhotoMiss:
        {
            NSString* text1 = @"Get access to your photo library?";
            NSString* text2 = @"To view photos MAImagePicker need access to your photo library";
            
            if ([UIAlertController class])
            {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle: text1 message: text2 preferredStyle: UIAlertControllerStyleAlert];
                [alert addAction: [UIAlertAction actionWithTitle: @"No"  style: UIAlertActionStyleCancel  handler: nil]];
                [alert addAction: [UIAlertAction actionWithTitle: @"Yes" style: UIAlertActionStyleDefault handler: ^(UIAlertAction *action) { [self askYes]; }]];
                [self presentViewController: alert animated: YES completion: nil];
            } else {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: text1 message: text2 delegate: self cancelButtonTitle: @"No" otherButtonTitles: @"Yes", nil];
                [alert show];
                [alert release];
            }
            break;
        }
            
        case MAPhotoOK:
            [self askYes];
            break;
            
        default:
        {
            NSString* msg = (access == MAPhotoNo) ? @"You declined access to photos" : @"Read photos error";
            if ([UIAlertController class])
            {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle: nil message: msg preferredStyle: UIAlertControllerStyleAlert];
                [alert addAction: [UIAlertAction actionWithTitle: @"OK" style: UIAlertActionStyleCancel handler: nil]];
                [self presentViewController: alert animated: YES completion: nil];
            } else {
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle: nil message: msg delegate: nil cancelButtonTitle: @"OK" otherButtonTitles:nil];
                [alert show];
                [alert release];
            }
            break;
        }
    }
    
    
}

//---------------------------------------------------------------------------------
- (void)askYes
{
    if (_popover)
    {
        [_popover dismissPopoverAnimated: YES];
        [_popover release];
        _popover = nil;
        return;
    }
    
    MAPickerController* vc = [[MAPickerController alloc] initWithDelegate: self maxSel: 3];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController: vc];
    [vc release];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        _popover = [[UIPopoverController alloc] initWithContentViewController: nav];
        _popover.delegate = self;
        [_popover presentPopoverFromRect: CGRectMake(10, 10, 30, 50) inView: self.view permittedArrowDirections:UIPopoverArrowDirectionDown animated: YES];
    } else {
        [self presentViewController: nav animated: YES completion: nil];
    }
    [nav release];
}

#define IMG_MAX_W 240
#define IMG_MAX_H 160

//---------------------------------------------------------------------------------
- (void)pickerOnOk: (NSArray*)items
{
    if (_popover)
    {
        [_popover dismissPopoverAnimated: YES];
        [_popover release];
        _popover = nil;
    } else {
        [self dismissViewControllerAnimated: YES completion: nil];
    }
    if (items)
    {
        [_items removeAllObjects];
        for (NSArray* item in items)
        {
            MAMediaType type = [[item firstObject] intValue];
            float w = 0;
            float h = 0;
            int d = 0;
            UIImage* img = nil;
            if (type == MAMediaPhotoAL || type == MAMediaVideoAL)
            {
                ALAsset* a = [item objectAtIndex: 1];
                img = [[UIImage alloc] initWithCGImage: [[a defaultRepresentation] fullScreenImage]];
                w = img.size.width;
                h = img.size.height;
                d = (type == MAMediaVideoAL) ? [[a valueForProperty: ALAssetPropertyDuration] intValue] : -1;
            } else {
                PHAsset* a = [item objectAtIndex: 1];
                w  = a.pixelWidth;
                h = a.pixelHeight;
                d = (type == MAMediaVideoPH) ? a.duration : -1;
            }
            if (w > IMG_MAX_W || h > IMG_MAX_H)
            {
                float k1 = IMG_MAX_W / w;
                float k2 = IMG_MAX_H / h;
                float k = (k1 < k2) ? k1 : k2;
                w *= k;
                h *= k;
            }
            NSNumber* wN = [[NSNumber alloc] initWithInt: w];
            NSNumber* hN = [[NSNumber alloc] initWithInt: h];
            NSNumber* dN = [[NSNumber alloc] initWithInt: d];
            NSMutableArray* item2 = [[NSMutableArray alloc] initWithObjects: [item firstObject], [item objectAtIndex: 1], wN, hN, dN, img, nil];
            [wN release];
            [hN release];
            [dN release];
            
            [_items addObject: item2];
            [item2 release];
            
            if (type == MAMediaPhotoPH || type == MAMediaVideoPH)
            {
                if (!_imgCache) _imgCache = [[PHCachingImageManager alloc] init];
                int n = (int)[_items count] - 1;
                [_imgCache requestImageForAsset: [item objectAtIndex: 1] targetSize: CGSizeMake(w * [[UIScreen mainScreen] scale], h * [[UIScreen mainScreen] scale])
                                                   contentMode: PHImageContentModeAspectFill options: nil
                                                 resultHandler: ^(UIImage *result, NSDictionary *info)
                 {
                     if (n < [_items count])
                     {
                         [[_items objectAtIndex: n] addObject: result];
                         [self.tableView reloadData];
                     }
                 }];
            }
        }
        [self.tableView reloadData];
    }
}


//---------------------------------------------------------------------------------
// <UIPopoverControllerDelegate>
//---------------------------------------------------------------------------------
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [_popover release];
    _popover = nil;
}

//---------------------------------------------------------------------------------
// <UIAlertViewDelegate>
//---------------------------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 0) [self askYes];
}

//---------------------------------------------------------------------------------
// <UITableViewDataSource>
//---------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return ([_items count]) ? 2 : 1;
}

//---------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == 0) ? 1 : [_items count];
}

#define MA_VIEW_CELL_ID @"V1"

//---------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: MA_VIEW_CELL_ID];
        if (!cell) cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: MA_VIEW_CELL_ID] autorelease];
        cell.textLabel.text = @"Select photos";
        return cell;
    }
    MAImageCell* cell = [tableView dequeueReusableCellWithIdentifier: [MAImageCell identifier]];
    if (!cell) cell = [[[MAImageCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: [MAImageCell identifier]] autorelease];
    [cell setItem: [_items objectAtIndex: indexPath.row]];
    return cell;
}

//---------------------------------------------------------------------------------
// <UITableViewDelegate>
//---------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) [self askAccess];
    [tableView deselectRowAtIndexPath: indexPath animated: YES];
}

//---------------------------------------------------------------------------------
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0) ? self.tableView.rowHeight : [[[_items objectAtIndex: indexPath.row] objectAtIndex: 3] intValue] + 10;
}

@end
