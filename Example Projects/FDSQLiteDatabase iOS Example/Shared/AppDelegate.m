#import "AppDelegate.h"
#import "FDDatabaseListController.h"


#pragma mark Class Definition

@implementation AppDelegate
{
	@private __strong UIWindow *_mainWindow;
}


#pragma mark - UIApplicationDelegate Methods

- (BOOL)application: (UIApplication *)application 
	didFinishLaunchingWithOptions: (NSDictionary *)launchOptions
{
	// Create the main window.
	UIScreen *mainScreen = [UIScreen mainScreen];
	
	_mainWindow = [[UIWindow alloc] 
		initWithFrame: mainScreen.bounds];
	
	_mainWindow.backgroundColor = [UIColor blackColor];
	
	// Create database list controller, wrap it in a navigation controller and add it to the main window.
	FDDatabaseListController *databaseListController = [[FDDatabaseListController alloc] 
		initWithDefaultNibName];
	
	UINavigationController *navigationController = [[UINavigationController alloc] 
		initWithRootViewController: databaseListController];
	
	_mainWindow.rootViewController = navigationController;
	
	// Show the main window.
	[_mainWindow makeKeyAndVisible];
	
	// Indicate success.
	return YES;
}


@end