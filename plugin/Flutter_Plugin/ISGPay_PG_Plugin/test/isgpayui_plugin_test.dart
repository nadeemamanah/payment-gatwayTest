import 'package:flutter_test/flutter_test.dart';
import 'package:isgpayui_plugin/isgpayui_plugin.dart';
import 'package:isgpayui_plugin/isgpayui_plugin_platform_interface.dart';
import 'package:isgpayui_plugin/isgpayui_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIsgpayuiPluginPlatform
    with MockPlatformInterfaceMixin
    implements IsgpayuiPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> initiateISGPayUI(Map inputArgs) {
    // TODO: implement initiateISGPayUI
    throw UnimplementedError();
  }
}

void main() {
  final IsgpayuiPluginPlatform initialPlatform = IsgpayuiPluginPlatform.instance;

  test('$MethodChannelIsgpayuiPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIsgpayuiPlugin>());
  });

  test('getPlatformVersion', () async {
    IsgpayuiPlugin isgpayuiPlugin = IsgpayuiPlugin();
    MockIsgpayuiPluginPlatform fakePlatform = MockIsgpayuiPluginPlatform();
    IsgpayuiPluginPlatform.instance = fakePlatform;

    expect(await isgpayuiPlugin.getPlatformVersion(), '42');
  });
}
