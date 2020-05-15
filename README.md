# dropbox

A flutter plugin for accessing Dropbox.

## Setup

Register a Dropbox API app from https://www.dropbox.com/developers .
You need dropbox key and dropbox secret.

For Android, add below in AndroidManifest.xml (replace DROPBOXKEY with your key)

        <activity
            android:name="com.dropbox.core.android.AuthActivity"
            android:configChanges="orientation|keyboard"
            android:launchMode="singleTask">
            <intent-filter>

                <!-- Change this to be db- followed by your app key -->
                <data android:scheme="db-DROPBOXKEY" />

                <action android:name="android.intent.action.VIEW" />

                <category android:name="android.intent.category.BROWSABLE" />
                <category android:name="android.intent.category.DEFAULT" />
            </intent-filter>
        </activity>

If you need more help setting up Android, please read https://github.com/dropbox/dropbox-sdk-java#setup .


For iOS, 
1) add below in Info.plist

        <key>LSApplicationQueriesSchemes</key>
          <array>
              <string>dbapi-8-emm</string>
              <string>dbapi-2</string>
          </array>

2) add below in Info.plist (replace DROPBOXKEY with your key)

        <key>CFBundleURLTypes</key>
          <array>
            <dict>
              <key>CFBundleURLSchemes</key>
              <array>
                <string>db-DROPBOXKEY</string>
              </array>
              <key>CFBundleURLName</key>
              <string></string>
            </dict>
          </array>
          
3) Add below code to AppDelegate.m

        #import <ObjectiveDropboxOfficial/ObjectiveDropboxOfficial.h>

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
        
If you need more help setting up for iOS, please read https://github.com/dropbox/dropbox-sdk-obj-c#get-started .


## Usage

```
import 'package:dropbox_client/dropbox_client.dart';

Future initDropbox() async {
    // init dropbox client. (call only once!)
    await Dropbox.init(dropbox_clientId, dropbox_key, dropbox_secret);
}

String accessToken;

Future testLogin() async {
  // this will run Dropbox app if possible, if not it will run authorization using a web browser.
  await Dropbox.authorize();
}

Future getAccessToken() async {
  accessToken = await Dropbox.getAccessToken();
}

Future loginWithAccessToken() async {
  await Dropbox.authorizeWithAccessToken(accessToken);
}

Future testListFolder() async {
  final result = await Dropbox.listFolder(''); // list root folder
  print(result);
  
  final url = await Dropbox.getTemporaryLink('/file.txt');
  print(url);
}

Future testUpload() async {
  final filepath = '/path/to/local/file.txt';
  final result = await Dropbox.upload(filepath, '/file.txt', (uploaded, total) {
    print('progress $uploaded / $total');
  });
}
```

Example can be found in example folder.
