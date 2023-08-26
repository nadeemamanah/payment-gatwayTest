import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isgpayui_plugin/isgpayui_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  String responseData = "Nothing";
  final _isgpayuiPlugin = IsgpayuiPlugin();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void startPlugin() async {
    String? result;

    try {
      result =
          await _isgpayuiPlugin.initiateISGPayUI(getArguments(100 * 100)) ??
              'Unknown platform version';
    } on PlatformException catch (e) {
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
      'passCode': '<Passcode>',
      'bankId': '<Bank ID>',
      'terminalId': '<Terminal ID>',
      'merchantId': '<Merchant ID>',
      'mcc': '<MCC>',
      'paymentType': 'Pay',
      'currency': "356",
      'email': '<Email ID>',
      'phone': '<Phone>',
      'hashKey': '<Hash Key>',
      'aesKey': '<AES Key>',
      'payOut': '',
      'orderInfo': '<Order ID>',
      'env': 'PROD', //UAT PROD
      'url': 'https://sandbox.isgpay.com/ISGPay-Genius/request.action',
    };
    return map;
  }
}
