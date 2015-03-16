//
//  MAAppDelegate.m
//
//

#import "MAAppDelegate.h"
#import "MAViewController.h"

@interface MAAppDelegate ()
{
    UIWindow* _window;
}
@end

//=================================================================================

@implementation MAAppDelegate

//---------------------------------------------------------------------------------
- (void)dealloc
{
    [_window release];
    [super dealloc];
}

//---------------------------------------------------------------------------------
- (BOOL)application: (UIApplication*)application didFinishLaunchingWithOptions: (NSDictionary*)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    
    MAViewController* vc = [[MAViewController alloc] initWithStyle: UITableViewStyleGrouped];
    UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController: vc];
    [vc release];
    
    _window.rootViewController = nav;
    [nav release];
    
    [_window makeKeyAndVisible];
    
    return YES;
}

@end

