import Flutter
import UIKit
import ISGPayUI

let baseDomain = "https://pgcloudpoc.insolutionsglobal.com:8464"
// let baseDomain = "https://sandbox.isgpay.com/"
var resultCallback:FlutterResult?

public class IsgpayuiPlugin: NSObject, FlutterPlugin {

//     let apiURL = baseDomain + "/ISGPay-Genius/request.action"
    var apiURL = ""
    let apiURLUPI = baseDomain + "/ISGPayNG/v2/upiRequest"
    let apiURLUPIStatus = baseDomain + "/ISGPayNG/v2/saleStatus"

    var customeResponseData = [String : Any]()

    public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "isgpayui_plugin", binaryMessenger: registrar.messenger())
    let instance = IsgpayuiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    
      resultCallback = result;
      
    if (call.method.elementsEqual("initiateISGPayUI")) {
        
        // Solution 1
        call.arguments.map { resData in
            
            if let receiveData = resData as? [String: Any]
            {
                let paymentData = receiveData["inputParams"] as? [String: String]
                self.paymentInitiationStart(dictData: paymentData)
            }
            else
            {
                //TODO return error
                customeResponseData["status"] = "F"
                customeResponseData["msg"] = "Invalid Input Params"
                result(customeResponseData)
            }
            
        }
        
    }
    else
    {
        result("iOS " + UIDevice.current.systemVersion)
    }
      
      
  }
    

    func paymentInitiationStart(dictData:[String: String]?) {
    
        var tempDictData = dictData ?? [String:String]()
        let formatter = DateFormatter()
        formatter.dateFormat = "ddhhMMHHmmss"
        formatter.string(from: Date())

        let strRandomTXNRefNo = "IOS_2_\(formatter.string(from: Date()))"

        var reqObj = ISGPayRequest()
        
        
        reqObj.Amount = tempDictData["amount"] ?? ""
        reqObj.BankId = tempDictData["bankId"] ?? ""
        reqObj.Environment = tempDictData["env"] ?? "" //UAT PROD
        reqObj.Email = tempDictData["email"] ?? ""
        reqObj.ExpiryDate = tempDictData["expiryDate"] ?? ""
        reqObj.Currency = tempDictData["currency"] ?? ""
        reqObj.CardNumber = tempDictData["cardNumber"] ?? ""
        reqObj.CardSecurityCode = tempDictData["cardSecurityCode"] ?? ""
        reqObj.TxnRefNo = tempDictData["txnRefNo"] ?? ""
        reqObj.TerminalId = tempDictData["terminalId"] ?? ""
        reqObj.TxnType = tempDictData["paymentType"] ?? ""
        reqObj.MerchantId = tempDictData["merchantId"] ?? ""
        reqObj.MCC = tempDictData["mcc"] ?? ""
        reqObj.OrderInfo = tempDictData["orderInfo"] ?? ""
        reqObj.payOpt = tempDictData["payOut"] ?? ""  //pass in case of 3-party  passempty ""  //dc
        reqObj.Phone = tempDictData["phone"] ?? ""
        reqObj.PassCode = tempDictData["passCode"] ?? ""
        reqObj.Version = tempDictData["version"] ?? ""
        reqObj.AESKey = tempDictData["aesKey"] ?? ""
        reqObj.SecureSecret = tempDictData["hashKey"] ?? ""
        apiURL = tempDictData["url"] ?? ""
    
        do {

            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

            if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

        // topController should now be your topmost view controller
            let isgPaymentController = ISGPayController.initiateISGPay(onViewController: topController, delegate: topController)
            isgPaymentController?.enableLog = true //to get log
            try isgPaymentController?.makePayment(payRequest: reqObj, baseURL: apiURL)
        }


        }
        catch let error {

            customeResponseData["status"] = "F"
            customeResponseData["msg"] = error.localizedDescription
            resultCallback?(customeResponseData)
        
        }
    
}
    
    
}

extension UIViewController :ISGPayControllerDelegate
{

    public func didFinishPaymentWithData(response: [String : Any]) {
        
        var customeResponseData = [String : Any]()
        customeResponseData["ResponseCode"] = "999999"
        customeResponseData["Message"] = "Oops, Something went wrong."
        customeResponseData["DebugMsg"] = "Faild didFinishPaymentWithData()"
        resultCallback?(response ?? customeResponseData)

    }
    
    

    public func didFailWithError(error: Error?) {

        var customeResponseData = [String : Any]()
        customeResponseData["ResponseCode"] = "999999"
        customeResponseData["Message"] = error?.localizedDescription ?? "Oops, Something went wrong."
        resultCallback?(customeResponseData)
    }


}
