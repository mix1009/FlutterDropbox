import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dropbox_client/dropbox_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String dropbox_clientId = 'test-flutter-dropbox';
const String dropbox_key = 'dropbox_key';
const String dropbox_secret = 'dropbox_secret';

void main() {
  return runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String accessToken;
  bool showInstruction = false;

  @override
  void initState() {
    super.initState();

    initDropbox();
  }

  Future initDropbox() async {
    if (dropbox_key == 'dropbox_key') {
      showInstruction = true;
      return;
    }

    await Dropbox.init(dropbox_clientId, dropbox_key, dropbox_secret);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString('dropboxAccessToken');

    setState(() {});
  }

  Future<bool> checkAuthorized(bool authorize) async {
    final token = await Dropbox.getAccessToken();
    if (token != null) {
      if (accessToken == null || accessToken.isEmpty) {
        accessToken = token;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('dropboxAccessToken', accessToken);
      }
      return true;
    }
    if (authorize) {
      if (accessToken != null && accessToken.isNotEmpty) {
        await Dropbox.authorizeWithAccessToken(accessToken);
        final token = await Dropbox.getAccessToken();
        if (token != null) {
          print('authorizeWithAccessToken!');
          return true;
        }
      } else {
        await Dropbox.authorize();
        print('authorize!');
      }
    }
    return false;
  }

  Future authorize() async {
    await Dropbox.authorize();
  }

  Future unlink() async {
    await deleteAccessToken();
    await Dropbox.unlink();
  }

  Future authorizeWithAccessToken() async {
    await Dropbox.authorizeWithAccessToken(accessToken);
  }

  Future deleteAccessToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('dropboxAccessToken');

    setState(() {
      accessToken = null;
    });
  }

  Future getAccountName() async {
    if (await checkAuthorized(true)) {
      final user = await Dropbox.getAccountName();
      print('user = $user');
    }
  }

  Future listFolder(path) async {
    if (await checkAuthorized(true)) {
      final result = await Dropbox.listFolder(path);
      setState(() {
        list = result;
      });
    }
  }

  Future uploadTest() async {
    if (await checkAuthorized(true)) {
      var tempDir = await getTemporaryDirectory();
      var filepath = '${tempDir.path}/test_upload.txt';
      File(filepath).writeAsStringSync(
          'contents.. from ' + (Platform.isIOS ? 'iOS' : 'Android') + '\n');

      final result =
          await Dropbox.upload(filepath, '/test_upload.txt', (uploaded, total) {
        print('progress $uploaded / $total');
      });
      print(result);
    }
  }

  Future downloadTest() async {
    if (await checkAuthorized(true)) {
      var tempDir = await getTemporaryDirectory();
      var filepath = '${tempDir.path}/test_download.zip'; // for iOS only!!
      print(filepath);

      final result = await Dropbox.download('/file_in_dropbox.zip', filepath,
          (downloaded, total) {
        print('progress $downloaded / $total');
      });

      print(result);
      print(File(filepath).statSync());
    }
  }

  Future<String> getTemporaryLink(path) async {
    final result = await Dropbox.getTemporaryLink(path);
    return result;
  }

  var list = List<dynamic>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dropbox example app'),
      ),
      body: showInstruction
          ? Instructions()
          : Builder(
              builder: (context) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Wrap(
                      children: <Widget>[
                        RaisedButton(
                          child: Text('authorize'),
                          onPressed: authorize,
                        ),
                        RaisedButton(
                          child: Text('authorizeWithAccessToken'),
                          onPressed: accessToken == null
                              ? null
                              : authorizeWithAccessToken,
                        ),
                        RaisedButton(
                          child: Text('unlink'),
                          onPressed: unlink,
                        ),
                        RaisedButton(
                          child: Text('list root folder'),
                          onPressed: () async {
                            await listFolder('');
                          },
                        ),
                        RaisedButton(
                          child: Text('test upload'),
                          onPressed: () async {
                            await uploadTest();
                          },
                        ),
                        RaisedButton(
                          child: Text('test download'),
                          onPressed: () async {
                            await downloadTest();
                          },
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final filesize = item['filesize'];
                          final path = item['pathLower'];
                          bool isFile = false;
                          var name = item['name'];
                          if (filesize == null) {
                            name += '/';
                          } else {
                            isFile = true;
                          }
                          return ListTile(
                              title: Text(name),
                              onTap: () async {
                                if (isFile) {
                                  final link = await getTemporaryLink(path);
                                  Scaffold.of(context).showSnackBar(
                                      SnackBar(content: Text(link)));
                                } else {
                                  await listFolder(path);
                                }
                              });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class Instructions extends StatelessWidget {
  const Instructions({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
              'You need to get dropbox_key & dropbox_secret from https://www.dropbox.com/developers'),
          SizedBox(height: 20),
          Text('1. Update dropbox_key and dropbox_secret from main.dart'),
          SizedBox(height: 20),
          Text(
              "  const String dropbox_key = 'DROPBOXKEY';\n  const String dropbox_secret = 'DROPBOXSECRET';"),
          SizedBox(height: 20),
          Text(
              '2. (Android) Update dropbox_key from android/app/src/main/AndroidManifest.xml.\n  <data android:scheme="db-DROPBOXKEY" />'),
          SizedBox(height: 20),
          Text(
              '2. (iOS) Update dropbox_key from ios/Runner/Info.plist.\n  <string>db-DROPBOXKEY</string>'),
        ],
      ),
    );
  }
}
