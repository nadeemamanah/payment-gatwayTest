import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:isgpayui_plugin/isgpayui_plugin.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String responseData = "Nothing";
  final _isgpayuiPlugin = IsgpayuiPlugin();

  @override
  void initState() {
    super.initState();
    // initPlatformState();
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Center(
            child: Column(
              children: [
                ElevatedButton(onPressed: () {
                  startPlugin();
                }, child: Text('Make Payment', style: TextStyle(fontSize: 17),)),
                Text('Result: $responseData\n' , style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _isgpayuiPlugin.getPlatformVersion() ?? 'Unknown platform version';
      // platformVersion = await _isgpayuiPlugin.initiateISGPayUI() ?? 'Unknown platform version';
      print(platformVersion);
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void startPlugin() async {
    String? result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _isgpayuiPlugin.initiateISGPayUI(getArguments(100*100)) ?? 'Unknown platform version';
    } on PlatformException catch(e){
      result = e.message;
    }

    debugPrint('Result ::: $result');

    setState(() {
      responseData = result!;
    });
  }


  Map getArguments(var amount) {

    var randomStr = DateTime.now().microsecondsSinceEpoch.toString();

    Map map = {


      'version': "1",
      'txnRefNo': "TX$randomStr", // Should change on every request
      'amount': '$amount',
      'passCode':  'SVPL4257',  //'ZCJE9606',
      'bankId': '000004', //'001001',
      'terminalId': '10100781', //'10000098',
      'merchantId': '101000000000781', //'300000000000248',
      'mcc':  '4112',  //'9399',
      'paymentType': 'Pay',
      'currency': "356",
      'email': 'test@gmail.com',
      'phone': '9806012254',
      'hashKey': 'E59CD2BF6F4D86B5FB3897A680E0DD3E', // '09C717844B3436C0A132A9C7D5AE9650',
      'aesKey':  '5EC4A697141C8CE45509EF485EE7D4B1', //'28A784E8B7E2017B5BEF412D14356906',
      'payOut': '',
      'orderInfo': '6075000000000023',
      'env': 'PROD', //UAT PROD
      'url': 'https://sandbox.isgpay.com/ISGPay-Genius/request.action',
      // 'cardNumber':  '5453010000095323',  // '4012001037141112',
      // 'expiryDate':  '022025',  //'012020',
      // 'cardSecurityCode': '123'
    };
    return map;

    // return json.encode(map);
  }

}
