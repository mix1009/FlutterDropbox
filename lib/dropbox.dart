import 'dart:async';

import 'package:flutter/services.dart';

class Dropbox {
  static const MethodChannel _channel = const MethodChannel('dropbox');

  static Future<bool> init(String clientId, String key, String secret) async {
    return await _channel.invokeMethod(
        'init', {'clientId': clientId, 'key': key, 'secret': secret});
  }

  static Future<void> authorize() async {
    await _channel.invokeMethod('authorize');
  }

  static Future<void> authorizeWithAccessToken(String accessToken) async {
    await _channel
        .invokeMethod('authorizeWithAccessToken', {'accessToken': accessToken});
  }

  // static Future<String> getAuthorizeUrl() async {
  //   return await _channel.invokeMethod('getAuthorizeUrl');
  // }

  // static Future<String> finishAuth(String code) async {
  //   return await _channel.invokeMethod('finishAuth', {'code': code});
  // }

  static Future<String> getAccessToken() async {
    return await _channel.invokeMethod('getAccessToken');
  }

  static Future<String> getAccountName() async {
    return await _channel.invokeMethod('getAccountName');
  }

  static Future listFolder(String path) async {
    return await _channel.invokeMethod('listFolder', {'path': path});
  }

  static Future<String> getTemporaryLink(String path) async {
    return await _channel.invokeMethod('getTemporaryLink', {'path': path});
  }
}
