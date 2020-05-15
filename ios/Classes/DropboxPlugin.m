#import "DropboxPlugin.h"
#import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

@interface DropboxPlugin () {
    NSString *appKey;
}
@end

FlutterMethodChannel* channel;

@implementation DropboxPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  channel = [FlutterMethodChannel
      methodChannelWithName:@"dropbox"
            binaryMessenger:[registrar messenger]];
  DropboxPlugin* instance = [[DropboxPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

+ (UIViewController*)topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}

- (NSString *)authURLwithAppKey:(NSString *)appKey {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  components.scheme = @"https";
  components.host = @"www.dropbox.com";
  components.path = @"/oauth2/authorize";

  NSString *localeIdentifier = [[NSBundle mainBundle] preferredLocalizations].firstObject ?: @"en";

  components.queryItems = @[
    [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"],
    [NSURLQueryItem queryItemWithName:@"client_id" value:appKey],
    [NSURLQueryItem queryItemWithName:@"disable_signup" value: @"true" ],
    [NSURLQueryItem queryItemWithName:@"locale" value:localeIdentifier],
  ];
  return [components.URL absoluteString];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"init" isEqualToString:call.method]) {
//      NSString *clientId = call.arguments[@"clientId"];
      NSString *key = call.arguments[@"key"];
//      NSString *secret = call.arguments[@"secret"];
      appKey = key;
      [DBClientsManager setupWithAppKey: key];
      result([NSNumber numberWithBool:TRUE]);

  } else if ([@"authorize" isEqualToString:call.method]) {

      [DBClientsManager authorizeFromController:[UIApplication sharedApplication]
                                     controller:[[self class] topMostController]
                                        openURL:^(NSURL *url) {
                                          NSLog(@"url = %@" , [url absoluteString]);
                                          [[UIApplication sharedApplication] openURL:url];
                                        }];
      result([NSNumber numberWithBool:TRUE]);
      
  } else if ([@"getAuthorizeUrl" isEqualToString:call.method]) {

      result([self authURLwithAppKey:appKey]);
      
  } else if ([@"finishAuth" isEqualToString:call.method]) {
//      NSString *code = call.arguments[@"code"];

      DBUserClient *client = [DBClientsManager authorizedClient];
      NSDictionary<NSString *, DBUserClient *> *clients =[DBClientsManager authorizedClients];
      NSLog(@"clients = %@", clients);
      for (NSString *key in clients.allKeys) {
          NSLog(@"key = %@", key);
          if (client == clients[key]) {
              result(key);
              return;
          }
      }

      result(client.accessToken);

  } else if ([@"authorizeWithAccessToken" isEqualToString:call.method]) {
      NSString *accessToken = call.arguments[@"accessToken"];

//      NSLog(@"clients = %@", [DBClientsManager authorizedClients]);
      [DBClientsManager authorizeClientFromKeychain:accessToken];
//      NSLog(@"clients = %@", [DBClientsManager authorizedClients]);

      result(@(TRUE));
      

  } else if ([@"getAccountName" isEqualToString:call.method]) {
      DBUserClient *client = [DBClientsManager authorizedClient];
      
      [[client.usersRoutes getCurrentAccount] setResponseBlock:^(DBUSERSFullAccount * _Nullable account, DBNilObject * _Nullable routeError, DBRequestError * _Nullable networkError) {
          result(account.name.displayName);
      }];

//      result(@"accountname");
  } else if ([@"listFolder" isEqualToString:call.method]) {
      NSString *path = call.arguments[@"path"];
      DBUserClient *client = [DBClientsManager authorizedClient];
      
      [[client.filesRoutes listFolder:path]
      setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderError *routeError, DBRequestError *networkError) {
       
      if (response) {
          NSArray<DBFILESMetadata *> *entries = response.entries;
          NSString *cursor = response.cursor;
          BOOL hasMore = [response.hasMore boolValue];
          
          NSMutableArray *arr = [self parseEntries: entries];

          if (hasMore) {
              [self listFolderContinue:cursor result:result array:arr];
          } else {
              NSLog(@"List folder complete.");
              result(arr);
          }
              
        } else {
          NSLog(@"%@\n%@\n", routeError, networkError);
        }
      }];

  } else if ([@"getAccessToken" isEqualToString:call.method]) {
      DBUserClient *client = [DBClientsManager authorizedClient];
      result(client.accessToken);
      
  } else if ([@"getTemporaryLink" isEqualToString:call.method]) {
      DBUserClient *client = [DBClientsManager authorizedClient];
      NSString *path = call.arguments[@"path"];

      [[client.filesRoutes getTemporaryLink:path] setResponseBlock:^(DBFILESGetTemporaryLinkResult *linkResult, DBFILESGetTemporaryLinkError * linkErr, DBRequestError* dbError) {
          if (linkResult) {
//                    NSLog(@"result = %@", result);
              if (linkResult.link) {
                  result(linkResult.link);
              } else {
                  result(@"error");
              }
          } else {
              result([NSString stringWithFormat:@"error = %@", linkErr]);
              NSLog(@"linkErr = %@", linkErr);
              NSLog(@"dbError = %@", dbError);
          }
      }];
  } else if ([@"upload" isEqualToString:call.method]) {
      NSString *filepath = call.arguments[@"filepath"];
      NSString *dropboxpath = call.arguments[@"dropboxpath"];
      NSNumber *key = call.arguments[@"key"];
      DBUserClient *client = [DBClientsManager authorizedClient];
      DBFILESWriteMode *mode = [[DBFILESWriteMode alloc] initWithOverwrite];

      NSError* error = nil;
      NSData* fileData = [NSData dataWithContentsOfFile:filepath  options:0 error:&error];

      [[[client.filesRoutes uploadData:dropboxpath mode:mode autorename:@(YES) clientModified:nil mute:@(NO) inputData:fileData]
        setResponseBlock:^(DBFILESFileMetadata *dResult, DBFILESUploadError *routeError, DBRequestError *networkError) {
          if (dResult) {
              NSLog(@"%@\n", dResult);
              result(@(TRUE));
          } else {
              NSLog(@"%@\n%@\n", routeError, networkError);
              result(@(FALSE));
          }
      }] setProgressBlock:^(int64_t bytesUploaded, int64_t totalBytesUploaded, int64_t totalBytesExpectedToUploaded) {
          NSLog(@"\n%lld\n%lld\n%lld\n", bytesUploaded, totalBytesUploaded, totalBytesExpectedToUploaded);
          [channel invokeMethod:@"progress" arguments:@[key, @(bytesUploaded)]];
      }];
  } else {
      NSLog(@"%@", call.method);
      NSLog(@"%@", call.arguments);
      result(@(TRUE));
//    result(FlutterMethodNotImplemented);
  }
}

- (NSMutableArray*) parseEntries: (NSArray<DBFILESMetadata *> *)entries {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"yyyyMMdd HHmmss";
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];

    NSMutableArray *arr = [[NSMutableArray alloc] init];
    
    for (DBFILESMetadata *entry in entries) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        
        [dict setValue:entry.name forKey:@"name"];
        [dict setValue:entry.pathLower forKey:@"pathLower"];
        [dict setValue:entry.pathDisplay forKey:@"pathDisplay"];
        
        if ([entry isKindOfClass:[DBFILESFolderMetadata class]]) {

        } else if ([entry isKindOfClass:[DBFILESFileMetadata class]]) {
            DBFILESFileMetadata *fileItem = (DBFILESFileMetadata *) entry;
            [dict setObject:fileItem.size forKey:@"filesize"];
            [dict setObject:[formatter stringFromDate: fileItem.clientModified] forKey:@"clientModified"];
            [dict setObject:[formatter stringFromDate: fileItem.serverModified] forKey:@"serverModified"];
        }
        [arr addObject:dict];
    }

    return arr;
}

- (void) listFolderContinue: (NSString *)cursor result:(FlutterResult) result array:(NSMutableArray*) arr {
    DBUserClient *client = [DBClientsManager authorizedClient];

    [[client.filesRoutes listFolderContinue:cursor] setResponseBlock:^(DBFILESListFolderResult *response, DBFILESListFolderContinueError * _Nullable routeError, DBRequestError * _Nullable networkError) {
        if (response) {
            NSArray<DBFILESMetadata *> *entries = response.entries;
            NSString *cursor = response.cursor;
            BOOL hasMore = [response.hasMore boolValue];
            
            [arr addObjectsFromArray:[self parseEntries: entries]];

            if (hasMore) {
                [self listFolderContinue:cursor result:result array:arr];
            } else {
                NSLog(@"List folder complete. (with continue)");
                result(arr);
            }
        } else {
            NSLog(@"%@\n%@\n", routeError, networkError);
        }
    }];
}

@end
