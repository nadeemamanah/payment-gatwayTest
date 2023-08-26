import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'isgpayui_plugin_platform_interface.dart';

/// An implementation of [IsgpayuiPluginPlatform] that uses method channels.
class MethodChannelIsgpayuiPlugin extends IsgpayuiPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('isgpayui_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> initiateISGPayUI(Map inputArgs) async {
    dynamic result = await methodChannel.invokeMethod<dynamic>('initiateISGPayUI', {"inputParams":inputArgs});
    final data = jsonEncode(result);
    print("CALL: initiateISGPayUI() :  $data");
    return data;
  }

}
