#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
  DBOAuthResult *authResult = [DBClientsManager handleRedirectURL:url];
  if (authResult != nil) {
    if ([authResult isSuccess]) {
      NSLog(@"Success! User is logged into Dropbox.");
    } else if ([authResult isCancel]) {
      NSLog(@"Authorization flow was manually canceled by user!");
    } else if ([authResult isError]) {
      NSLog(@"Error: %@", authResult);
    }
  }
  return NO;
}

@end
