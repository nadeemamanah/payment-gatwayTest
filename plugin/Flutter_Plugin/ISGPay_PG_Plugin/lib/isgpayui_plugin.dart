
import 'isgpayui_plugin_platform_interface.dart';

class IsgpayuiPlugin {
  Future<String?> getPlatformVersion() {
    return IsgpayuiPluginPlatform.instance.getPlatformVersion();
  }


  Future<String?> initiateISGPayUI(Map inputArgs) async {
    return IsgpayuiPluginPlatform.instance.initiateISGPayUI(inputArgs);
  }
}
