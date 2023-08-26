import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'isgpayui_plugin_method_channel.dart';

abstract class IsgpayuiPluginPlatform extends PlatformInterface {
  /// Constructs a IsgpayuiPluginPlatform.
  IsgpayuiPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static IsgpayuiPluginPlatform _instance = MethodChannelIsgpayuiPlugin();

  /// The default instance of [IsgpayuiPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelIsgpayuiPlugin].
  static IsgpayuiPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IsgpayuiPluginPlatform] when
  /// they register themselves.
  static set instance(IsgpayuiPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> initiateISGPayUI(Map inputArgs) {
    throw UnimplementedError('initiateISGPayUI has not been implemented.');
  }
}
