//
//  ISGPayController.swift
//  ISGPayUI
//
//  Created by isg mobile on 11/08/22.
//

import UIKit
import WebKit

enum RequestError: Error {
    case emptySecureSecret
    case emptyAESKey
    case emptyTxnRefNo
    case emptyAmount
    case emptyPassCode
    case emptyBankId
    case emptyTerminalId
    case emptyMerchantId
    case emptyMCC
    case emptyCurrency
    case emptyTxnType
    case emptyOrderInfo
    case emptyEmail
    case emptyPhone
    case emptypayOpt
    case emptyCardNumber
    case emptyExpiryDate
    case emptyCardSecurityCode
    case emptyBankCode
    case emptyFirstName
    case emptyLastName
    case emptyStreet
    case emptyCity
    case emptyZIP
    case emptyState
    case emptyVersion
    case emptyEnvironment
    case emptyOrderId
    case emptyAccessCode
}


@objc public protocol ISGPayControllerDelegate {
    func didFinishPaymentWithData(response:[String:Any])
    func didFailWithError(error:Error?)
    
    @objc optional func didFinishWithUPI()
}



/*
  ISGPayController
 
 991 - Server response error
 992 - Response encData is empty
 993 - Main response error
 994 - Response EncData Decryption error
 
*/
public class ISGPayController: UIViewController {
    
    ///Optional - Boolean - true: To print framework log
    public var enableLog:Bool = false
    
    
    var payReqObj:ISGPayRequest!
    var payUpiReqObj:ISGUpiPayRequest!
    
    var delegate:ISGPayControllerDelegate?
    var viewController:UIViewController?
    
    
    var activityIndicator: UIActivityIndicatorView!
    var lblPleaseWait:UILabel!
    var wkWebView:WKWebView!
//    var transactionResponse:ISGPayResponse!
    
    var webViewForServerTransaction:UIWebView!
    var isServerProcessed = false
    
    
    
    public static func initiateISGPay(onViewController:UIViewController, delegate:ISGPayControllerDelegate?) -> ISGPayController?
    {
        var isgPaymentController:ISGPayController!
        
        //        try validateRequest(payRequest: payRequest)
        
        if let currentView = onViewController.view
        {
            isgPaymentController =  ISGPayController()
            isgPaymentController.view.frame = currentView.bounds;
            isgPaymentController.delegate = delegate;
            isgPaymentController.viewController = onViewController;

            //            isgPaymentController.payReqObj = payRequest;
            //
            //            isgPaymentController.isServerProcessed = false
            //            if let tempEncData = payRequest.encData
            //            {
            //                if tempEncData != ""
            //                {
            //                    isgPaymentController.isServerProcessed = true
            //                }
            //            }
            currentView.addSubview(isgPaymentController.view)
            onViewController.addChild(isgPaymentController)
            isgPaymentController.didMove(toParent: onViewController)
        }
        
        return isgPaymentController;
    }
    
    
  
    public static func checkUPIStatus(upiStatusRequest:ISGUpiStatusRequest, delegate:ISGPayControllerDelegate?, enableLog:Bool = false, baseURL:String, completionHandler: @escaping (_ status:Bool, _ response:String?, _ error:Error?) -> Void) throws
    {
        
        var isEncDataServerProcessed = false
        if let tempEncData = upiStatusRequest.encData
        {
            if tempEncData != ""
            {
                isEncDataServerProcessed = true
            }
        }
        
        try validateUpiStatusRequest(request: upiStatusRequest, isServerProcessEncData:isEncDataServerProcessed, enableLog: enableLog)
        
        
        if enableLog
        {
            print("Version: \(Constant.kVersion)")
            print("Environment: \(upiStatusRequest.Environment!)")
        }
        
        var transaction = [String:String]()
        
        //            transaction["Version"] = payRequest.Version ?? "1";
        transaction["BankId"] = upiStatusRequest.BankId ?? "";
        transaction["TerminalId"] = upiStatusRequest.TerminalId ?? "";
        transaction["MerchantId"] = upiStatusRequest.MerchantId ?? "";
        transaction["OrderId"] = upiStatusRequest.OrderId ?? "";
        transaction["AccessCode"] = upiStatusRequest.AccessCode ?? "";
        transaction["TxnType"] = upiStatusRequest.TxnType ?? ""; //@"Status";
        
        
        if isEncDataServerProcessed == true
        {
            
            ISGPayController.checkApiCallForUPI(strEncValue: upiStatusRequest.encData ?? "", transactionObj: transaction, strEnvironment: upiStatusRequest.Environment,  aesKey: "", enableLog:enableLog, baseURL:baseURL) { status, response, error in
                
                completionHandler(status, response, error)
                return
            }
            
        }
        else
        {
            
            var arrKeys = Array(transaction.keys) //.dictTransactionData.allKeys;
            arrKeys.sort()
            
            var strHastRawData = upiStatusRequest.SecureSecret ?? ""
            for key in arrKeys
            {
                if let temp = transaction[key]
                {
                    if temp != ""
                    {
                        strHastRawData = strHastRawData + temp
                    }
                }
            }
            
            let secureHash = ISGCryptography.sha256Hash(for: strHastRawData) ?? ""
            let strAESInputBeforeEncryption = ISGPayController.upiEncriptionInputStringFrom(dictData: transaction, hashValue: secureHash)
            
                        
            let strAESInputAfterEncryption = ISGCryptography.encryptedString(strAESInputBeforeEncryption, withKey: upiStatusRequest.AESKey) ?? ""

            
            if enableLog {
                print("KEYS--->>\(arrKeys)")
                print("HASH RAW DATA---->>\(strHastRawData)")
                print("SECURE HASH---->>\(secureHash)")
                print("RAW DATA--> \(strAESInputBeforeEncryption)")
                print("After Encryption DATA--> \(strAESInputAfterEncryption)")
            }
            
            ISGPayController.checkApiCallForUPI(strEncValue: strAESInputAfterEncryption, transactionObj: transaction, strEnvironment: upiStatusRequest.Environment, aesKey: upiStatusRequest.AESKey ?? "", enableLog:enableLog, baseURL:baseURL) { status, response, error in
                completionHandler(status, response, error)
                return
            }
            
            
        }
        
    }
    
    
    static func checkApiCallForUPI(strEncValue:String, transactionObj:[String:String], strEnvironment:String, aesKey: String, enableLog:Bool = false, baseURL:String, completionHandler: @escaping (_ status:Bool, _ response:String?, _ error: Error?) -> Void)
    {
        var reqURL = URL(string: Constant.kRequestURLUPIStatusUAT)
        
        if strEnvironment.uppercased() == "PROD"
        {
            reqURL = URL(string: Constant.kRequestURLUPIStatus)
            print("*****####*** ISG UPI PRODUCTION PG FRAMEWORK ***####****")
        }
        else
        {
            print("*****####*** ISG UPI UAT PG FRAMEWORK ***####****")
        }

        if let tempURL = URL(string: baseURL)
        {
            reqURL = tempURL
        }
        else
        {
            print("*****####*** DEFAULT BASE URL ***####****")
        }
        
                
        guard let tReqURL = reqURL else {
            print("*****####*** UPI URL ISSUE ***####****")
            return
        }
        
        
        //        var config = URLSessionConfiguration.default
        //        var header = [String:String]()
        //        header["Accept"] = "application/json"
        //        header["X-Application"] = "<AppKey>"
        //        header["Content-Type"] = "application/x-www-form-urlencoded"
        //        config.httpAdditionalHeaders = header
        
        //        let sessionConfiguration = URLSessionConfiguration.default
        //        var session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let params = ISGPayController.upiRequestDataWithEncriptedValue(strEncValue: strEncValue, transactionObj: transactionObj)
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        
        if let temp = jsonData, let string = String(data: temp, encoding: String.Encoding.utf8) {
            if enableLog
            {
                print(string)
            }
        }
        
        var request = URLRequest(url: tReqURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let data = data, error == nil else {
                if enableLog
                {
                    print(error?.localizedDescription ?? "No data")
                    print("991 - Server response error")
                }
                
                let err = NSError(domain: "UPI", code: 991, userInfo: [ "errorCode": "991", "errorMessage": "Something went wrong(991)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"991 - Server response error"])
                completionHandler(false, nil, err)
                return
            }
            
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                if enableLog
                {
                    print(string)
                }
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if let responseJSON = responseJSON as? [String: Any] {
                if enableLog
                {
                    print(responseJSON)
                }
                
                
                if ((responseJSON["errorCode"] as? String) ?? "") == "00"
                {
                    if ((responseJSON["encData"] as? String) ?? "") != "" {
                        if aesKey == "" // server processed request
                        {
                            completionHandler(true, "\(responseJSON["encData"] ?? "")" , nil)
                            return
                        }
                        else
                        {
                            let strAESInputAfterDecryption = ISGCryptography.decryptedString("\(responseJSON["encData"] ?? "")", withKey: aesKey)
                            
                            if strAESInputAfterDecryption != ""
                            {
                                completionHandler(true, strAESInputAfterDecryption, nil)
                                return
                            }
                            else
                            {
                                let err = NSError(domain: "UPI", code: 994, userInfo: [ "errorCode": "994", "errorMessage": "Something went wrong(994)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"994 - Response EncData Decryption error"])
                                completionHandler(false, nil, err)
                                return
                            }
                        }
                    }
                    else
                    {
                        let err = NSError(domain: "UPI", code: 992, userInfo: [ "errorCode": "992", "errorMessage": "Something went wrong(992)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"992 - Response encData is empty"])
                        completionHandler(false, nil, err)
                        return
                    }
                }
                else
                {
                    let errorCode = (responseJSON["errorCode"] as? String) ?? ""
                    let errorMessage = (responseJSON["errorMessage"] as? String) ?? ""
                    
                    var err = NSError(domain: "UPI", code: 995, userInfo: [ "errorCode": "995", "errorMessage": "Something went wrong(995)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"995 - Main response error"])
                    if(errorCode != "" && errorMessage != "")
                    {
                        err = NSError(domain: "UPI", code: 996, userInfo: [ "errorCode": "\(errorCode)", "errorMessage": "\(errorMessage)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"\(errorCode) - \(errorMessage)"])
                    }
                    
                    completionHandler(false, nil, err)
                    return
                }
                    
                
            }
            else
            {
                let err = NSError(domain: "UPI", code: 993, userInfo: [ "errorCode": "993", "errorMessage": "Something went wrong(993)", NSLocalizedDescriptionKey: "Something went wrong", "developerLog":"993 - Main response error"])
                completionHandler(false, nil, err)
                return
            }
        }
        
        task.resume()
        
        
        //        if #available(iOS 12.0, *) {
        //            // Use iOS 11 APIs.
        //            wkWebView.load(request)
        //
        //        } else {
        //            // Alternative code for earlier versions of iOS.
        //            webViewForServerTransaction.loadRequest(request)
        //        }
        return;
        
    }
    
    public static func getVersion() -> String
    {
        return Constant.kVersion
    }
    
    ///PG Transaction
    public func makePayment(payRequest:ISGPayRequest, baseURL:String) throws
    {
        
        self.payReqObj = payRequest;
        
        if self.enableLog
        {
            print("Version: \(Constant.kVersion)")
            print("Environment: \(self.payReqObj.Environment!)")
        }
        
        self.isServerProcessed = false
        if let tempEncData = payRequest.encData
        {
            if tempEncData != ""
            {
                self.isServerProcessed = true
            }
        }
        
        if self.isServerProcessed == false
        {
            try validateRequest(payRequest: payRequest)
        }
        
        
        if self.parent != nil
        {
            
            activityIndicator.startAnimating()
            if #available(iOS 12.0, *) {
                // Use iOS 11 APIs.
                wkWebView = WKWebView(frame: self.view.bounds)
                self.view.addSubview(wkWebView)
                wkWebView.isHidden = true
                wkWebView.uiDelegate = self
                wkWebView.navigationDelegate = self
                
            } else {
                // Alternative code for earlier versions of iOS.
                webViewForServerTransaction = UIWebView(frame:self.view.bounds)
                self.view.addSubview(webViewForServerTransaction)
                webViewForServerTransaction.isHidden = true
                webViewForServerTransaction.delegate = self
            }
            
            
            lblPleaseWait.isHidden = false;
            
            self.view.addSubview(activityIndicator)
            self.view.addSubview(lblPleaseWait)
            
            var transaction = [String:String]()
            
            transaction["Version"] = self.payReqObj.Version ?? "1";
            
            transaction["BankId"] = self.payReqObj.BankId;
            transaction["TerminalId"] = self.payReqObj.TerminalId; //@"20001562";
            transaction["MerchantId"] = self.payReqObj.MerchantId; //@"TESTMERCHANT001";
            transaction["TxnRefNo"] = self.payReqObj.TxnRefNo;
            
            transaction["MCC"] = self.payReqObj.MCC; //@"5974";
            transaction["PassCode"] = self.payReqObj.PassCode; //@"JJRS7608";
            transaction["TxnType"] = self.payReqObj.TxnType; //@"Pay";
            transaction["Currency"] = self.payReqObj.Currency; //@"356";
            transaction["Amount"] = self.payReqObj.Amount; //@"10000";
            
            transaction["OrderInfo"] = self.payReqObj.OrderInfo; // @"6075000000000023";
            transaction["payOpt"] = self.payReqObj.payOpt; //@""; //ask rohit what to pass in case of 3-party  pass empty ""  //dc
            
            transaction["CardNumber"] =  self.payReqObj.CardNumber; //@"4012001037141112";
            transaction["ExpiryDate"] =  self.payReqObj.ExpiryDate; //@"012020";
            transaction["CardSecurityCode"] =  self.payReqObj.CardSecurityCode; //@"123";
            
            transaction["ReturnURL"] = "mobile://processisgpay.mobile";//@"ios://loadresponce.ios";
            
            
            if !(self.payReqObj.FirstName ?? "").isEmpty {
                transaction["FirstName"] = self.payReqObj.FirstName ?? ""
            }
            
            if !(self.payReqObj.LastName ?? "").isEmpty {
                transaction["LastName"] = self.payReqObj.LastName ?? ""
            }
            
            if !(self.payReqObj.Street ?? "").isEmpty {
                transaction["Street"] = self.payReqObj.Street ?? ""
            }
            
            if !(self.payReqObj.City ?? "").isEmpty {
                transaction["City"] = self.payReqObj.City ?? ""
            }
            
            if !(self.payReqObj.State ?? "").isEmpty {
                transaction["State"] = self.payReqObj.State ?? ""
            }
            if !(self.payReqObj.ZIP ?? "").isEmpty {
                transaction["ZIP"] = self.payReqObj.ZIP ?? ""
            }
            if !(self.payReqObj.Email ?? "").isEmpty {
                transaction["Email"] = self.payReqObj.Email ?? ""
            }
            if !(self.payReqObj.Phone ?? "").isEmpty {
                transaction["Phone"] = self.payReqObj.Phone ?? ""
            }
            if !(self.payReqObj.UDF01 ?? "").isEmpty {
                transaction["UDF01"] = self.payReqObj.UDF01 ?? ""
            }
            if !(self.payReqObj.UDF02 ?? "").isEmpty {
                transaction["UDF02"] = self.payReqObj.UDF02 ?? ""
            }
            if !(self.payReqObj.UDF03 ?? "").isEmpty {
                transaction["UDF03"] = self.payReqObj.UDF03 ?? ""
            }
            if !(self.payReqObj.UDF04 ?? "").isEmpty {
                transaction["UDF04"] = self.payReqObj.UDF04 ?? ""
            }
            if !(self.payReqObj.UDF05 ?? "").isEmpty {
                transaction["UDF05"] = self.payReqObj.UDF05 ?? ""
            }
            if !(self.payReqObj.UDF06 ?? "").isEmpty {
                transaction["UDF06"] = self.payReqObj.UDF06 ?? ""
            }
            if !(self.payReqObj.UDF07 ?? "").isEmpty {
                transaction["UDF07"] = self.payReqObj.UDF07 ?? ""
            }
            if !(self.payReqObj.UDF08 ?? "").isEmpty {
                transaction["UDF08"] = self.payReqObj.UDF08 ?? ""
            }
            if !(self.payReqObj.UDF09 ?? "").isEmpty {
                transaction["UDF09"] = self.payReqObj.UDF09 ?? ""
            }
            if !(self.payReqObj.UDF10 ?? "").isEmpty {
                transaction["UDF10"] = self.payReqObj.UDF10 ?? ""
            }
            
            
            if !(self.payReqObj.BankCode ?? "").isEmpty {
                transaction["BankCode"] = self.payReqObj.BankCode ?? ""
            }
            if !(self.payReqObj.chTokenizationConsent ?? "").isEmpty {
                transaction["chTokenizationConsent"] = self.payReqObj.chTokenizationConsent ?? ""
            }
            if !(self.payReqObj.chUserID ?? "").isEmpty {
                transaction["chUserID"] = self.payReqObj.chUserID ?? ""
            }
            if !(self.payReqObj.CardTokenPan ?? "").isEmpty {
                transaction["CardTokenPan"] = self.payReqObj.CardTokenPan ?? ""
            }
            if !(self.payReqObj.CardTokenExpiry ?? "").isEmpty {
                transaction["CardTokenExpiry"] = self.payReqObj.CardTokenExpiry ?? ""
            }
            if !(self.payReqObj.CardTokenCrypto ?? "").isEmpty {
                transaction["CardTokenCrypto"] = self.payReqObj.CardTokenCrypto ?? ""
            }
            if !(self.payReqObj.MerchantTRID ?? "").isEmpty {
                transaction["MerchantTRID"] = self.payReqObj.MerchantTRID ?? ""
            }
            if !(self.payReqObj.CardTokenReferenceNo ?? "").isEmpty {
                transaction["CardTokenReferenceNo"] = self.payReqObj.CardTokenReferenceNo ?? ""
            }
            
            
            
            
            
            
            
            if self.isServerProcessed == true
            {
                if let tempEncData = self.payReqObj.encData
                {
                    
                    self.apiCallWithEncriptedValue(strEncValue: tempEncData, transactionObj: transaction, strEnvironment: self.payReqObj.Environment, baseURL: baseURL)
                }
                else
                {
                    //NSLog(@"Don't Make Payment");
                    self.activityIndicator.stopAnimating()
                    self.lblPleaseWait.isHidden = true
                    if self.enableLog
                    {
                        
                        print("Parameter Data missing")
                    }
                }
                
            }
            else
            {
                
                //NSLog(transaction.TxnRefNo,nil);
                //NSLog(@"%@", transaction.dictTransactionData);
                
                
                var arrKeys = Array(transaction.keys) //.dictTransactionData.allKeys;
                
                arrKeys = self.sortArray(arr: arrKeys)
                
                //                print(arrKeys1)
                //                //arrKeys.sort() //[arrKeys sortedArrayUsingSelector:@selector(compare:)];
                ////                arrKeys = arrKeys.sorted(by: { $0.compare($1) })
                //                //let arrKeys =
                //                let arrKeys = arrKeys1.sorted { (lhs: String, rhs: String) -> Bool in
                //                    return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                //                }
                
                //                [arrKeys sortedArrayUsingSelector:@selector(compare:)];
                
                var strHastRawData = self.payReqObj.SecureSecret ?? ""
                for key in arrKeys
                {
                    if let temp = transaction[key]
                    {
                        if temp != ""
                        {
                            strHastRawData = strHastRawData + temp
                        }
                    }
                }
                
                if self.enableLog {
                    print(strHastRawData)
                }
                                
                
                let secureHash = ISGCryptography.sha256Hash(for: strHastRawData) ?? ""
                let strAESInputBeforeEncription = self.encriptionInputStringFrom(dictData: transaction, hashValue: secureHash)
                if self.enableLog {
                    print("RAW DATA--> \(strAESInputBeforeEncription)")
                }
                
                                
                let strAESInputAfterEncription = ISGCryptography.encryptedString(strAESInputBeforeEncription, withKey: self.payReqObj.AESKey) ?? ""
                
               
                
                if self.enableLog {
                  print("ENC DATA--> \(strAESInputAfterEncription)")
                }
                
                self.apiCallWithEncriptedValue(strEncValue: strAESInputAfterEncription, transactionObj: transaction, strEnvironment: self.payReqObj.Environment, baseURL: baseURL)
            }
            
            
        }
        else
        {
            //NSLog(@"Don't Make Payment");
            self.activityIndicator.stopAnimating()
            self.lblPleaseWait.isHidden = true
            if self.enableLog
            {
                
                print("Parameter Data missing")
            }
        }
        
        
    }
    
    
    ///UPI Intent
    public func makePayment(payUpiRequest:ISGUpiPayRequest, baseURL:String) throws
    {
        
        if self.enableLog
        {
            print("Version: \(Constant.kVersion)")
        }
        
        self.payUpiReqObj = payUpiRequest;
        self.isServerProcessed = false
        if let tempEncData = payUpiRequest.encData
        {
            if tempEncData != ""
            {
                self.isServerProcessed = true
            }
        }
        
        if self.isServerProcessed == false
        {
            try validateUPIRequest(payRequest: payUpiRequest)
        }
        
        if self.parent != nil
        {
            
            activityIndicator.startAnimating()
            //            if #available(iOS 12.0, *) {
            //                // Use iOS 11 APIs.
            //                wkWebView = WKWebView(frame: self.view.bounds)
            //                self.view.addSubview(wkWebView)
            //                wkWebView.isHidden = true
            //                wkWebView.uiDelegate = self
            //                wkWebView.navigationDelegate = self
            //
            //            } else {
            //                // Alternative code for earlier versions of iOS.
            //                webViewForServerTransaction = UIWebView(frame:self.view.bounds)
            //                self.view.addSubview(webViewForServerTransaction)
            //                webViewForServerTransaction.isHidden = true
            //                webViewForServerTransaction.delegate = self
            //            }
            
            self.lblPleaseWait.isHidden = false;
            self.view.addSubview(activityIndicator)
            self.view.addSubview(lblPleaseWait)
            
            var transaction = [String:String]()
            
            //            transaction["Version"] = payRequest.Version ?? "1";
            transaction["BankId"] = payUpiRequest.BankId;
            transaction["TerminalId"] = payUpiRequest.TerminalId; //@"20001562";
            transaction["MerchantId"] = payUpiRequest.MerchantId; //@"TESTMERCHANT001";
            transaction["OrderId"] = payUpiRequest.OrderId;
            
            transaction["MCC"] = payUpiRequest.MCC; //@"5974";
            transaction["AccessCode"] = payUpiRequest.AccessCode; //@"JJRS7608";
            transaction["Command"] = payUpiRequest.Command; //@"Pay";
            transaction["Currency"] = payUpiRequest.Currency; //@"356";
            transaction["Amount"] = payUpiRequest.Amount; //@"10000";
            
            transaction["OrderInfo"] = payUpiRequest.OrderInfo; // @"6075000000000023";
            transaction["PaymentOption"] = payUpiRequest.PaymentOption; //@""; //ask rohit what to pass in case of 3-party  pass empty ""  //dc
            
            //            transaction["ReturnURL"] = "mobile://processisgpay.ios";//@"ios://loadresponce.ios";
            
            if !(payUpiRequest.chFirstName ?? "").isEmpty {
                transaction["chFirstName"] = payUpiRequest.chFirstName ?? ""
            }
            
            if !(payUpiRequest.chLastName ?? "").isEmpty {
                transaction["chLastName"] = payUpiRequest.chLastName ?? ""
            }
            
            if !(payUpiRequest.chAddrStreet ?? "").isEmpty {
                transaction["chAddrStreet"] = payUpiRequest.chAddrStreet ?? ""
            }
            
            if !(payUpiRequest.chAddrCity ?? "").isEmpty {
                transaction["chAddrCity"] = payUpiRequest.chAddrCity ?? ""
            }
            
            if !(payUpiRequest.chAddrState ?? "").isEmpty {
                transaction["chAddrState"] = payUpiRequest.chAddrState ?? ""
            }
            if !(payUpiRequest.chAddrZip ?? "").isEmpty {
                transaction["chAddrZip"] = payUpiRequest.chAddrZip ?? ""
            }
            if !(payUpiRequest.chEmail ?? "").isEmpty {
                transaction["chEmail"] = payUpiRequest.chEmail ?? ""
            }
            if !(payUpiRequest.chPhone ?? "").isEmpty {
                transaction["chPhone"] = payUpiRequest.chPhone ?? ""
            }
            if !(payUpiRequest.IpAddress ?? "").isEmpty {
                //removed as per PG team
//                transaction["IpAddress"] = payUpiRequest.IpAddress ?? ""
            }
            
            
            if !(payUpiRequest.UDF01 ?? "").isEmpty {
                transaction["UDF01"] = payUpiRequest.UDF01 ?? ""
            }
            if !(payUpiRequest.UDF02 ?? "").isEmpty {
                transaction["UDF02"] = payUpiRequest.UDF02 ?? ""
            }
            if !(payUpiRequest.UDF03 ?? "").isEmpty {
                transaction["UDF03"] = payUpiRequest.UDF03 ?? ""
            }
            if !(payUpiRequest.UDF04 ?? "").isEmpty {
                transaction["UDF04"] = payUpiRequest.UDF04 ?? ""
            }
            if !(payUpiRequest.UDF05 ?? "").isEmpty {
                transaction["UDF05"] = payUpiRequest.UDF05 ?? ""
            }
            if !(payUpiRequest.UDF06 ?? "").isEmpty {
                transaction["UDF06"] = payUpiRequest.UDF06 ?? ""
            }
            if !(payUpiRequest.UDF07 ?? "").isEmpty {
                transaction["UDF07"] = payUpiRequest.UDF07 ?? ""
            }
            if !(payUpiRequest.UDF08 ?? "").isEmpty {
                transaction["UDF08"] = payUpiRequest.UDF08 ?? ""
            }
            if !(payUpiRequest.UDF09 ?? "").isEmpty {
                transaction["UDF09"] = payUpiRequest.UDF09 ?? ""
            }
            if !(payUpiRequest.UDF10 ?? "").isEmpty {
                transaction["UDF10"] = payUpiRequest.UDF10 ?? ""
            }
            
            
            if !(payUpiRequest.TransactionNote ?? "").isEmpty {
                transaction["TransactionNote"] = payUpiRequest.TransactionNote ?? ""
            }
            if !(payUpiRequest.MerchantReturnURL ?? "").isEmpty {
                transaction["MerchantReturnURL"] = payUpiRequest.MerchantReturnURL ?? ""
            }
            
            
            
            if self.isServerProcessed == true
            {
                if let tempEncData = payUpiRequest.encData
                {
                    self.UPIApiCallWithEncriptedValue(strEncValue: tempEncData, transactionObj: transaction, strEnvironment: payUpiRequest.Environment, baseURL:baseURL)
                }
                else
                {
                    //NSLog(@"Don't Make Payment");
                    self.activityIndicator.stopAnimating()
                    self.lblPleaseWait.isHidden = true
                    if self.enableLog
                    {
                        
                        print("Parameter Data missing")
                    }
                }
                
            }
            else
            {
                
                //NSLog(transaction.TxnRefNo,nil);
                //NSLog(@"%@", transaction.dictTransactionData);
                
                
                var arrKeys = Array(transaction.keys) //.dictTransactionData.allKeys;
                
                arrKeys = self.sortArray(arr: arrKeys)
                
                //                print(arrKeys1)
                //                //arrKeys.sort() //[arrKeys sortedArrayUsingSelector:@selector(compare:)];
                ////                arrKeys = arrKeys.sorted(by: { $0.compare($1) })
                //                //let arrKeys =
                //                let arrKeys = arrKeys1.sorted { (lhs: String, rhs: String) -> Bool in
                //                    return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
                //                }
                
                //                [arrKeys sortedArrayUsingSelector:@selector(compare:)];
                
                var strHastRawData = payUpiRequest.SecureSecret ?? ""
                for key in arrKeys
                {
                    if let temp = transaction[key]
                    {
                        if temp != ""
                        {
                            strHastRawData = strHastRawData + temp
                        }
                    }
                }
                
                if self.enableLog {
                    print("arrKeys---->>\(arrKeys)")
                }
                
                if self.enableLog {
                    print("strHastRawData---->>\(strHastRawData)")
                }
                let secureHash = ISGCryptography.sha256Hash(for: strHastRawData) ?? ""
                let strAESInputBeforeEncription = ISGPayController.upiEncriptionInputStringFrom(dictData: transaction, hashValue: secureHash)
                if self.enableLog {
                    print("RAW DATA--> \(strAESInputBeforeEncription)")
                }
                //                print("AES OUT--> \(strAESInputBeforeEncription)")
                let strAESInputAfterEncription = ISGCryptography.encryptedString(strAESInputBeforeEncription, withKey: payUpiRequest.AESKey) ?? ""
//                                print("AES OUT--> \(strAESInputAfterEncription)")
                
                
                self.UPIApiCallWithEncriptedValue(strEncValue: strAESInputAfterEncription, transactionObj: transaction, strEnvironment: payUpiRequest.Environment, baseURL: baseURL)
            }
            
            
        }
        else
        {
            //NSLog(@"Don't Make Payment");
            self.activityIndicator.stopAnimating()
            self.lblPleaseWait.isHidden = true
            if self.enableLog
            {
                
                print("Parameter Data missing")
            }
        }
        
        
    }
    
    func validateRequest(payRequest:ISGPayRequest) throws
    {
        
        if let encData = payRequest.encData
        {
            if encData.isEmpty
            {
                if payRequest.SecureSecret.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptySecureSecret
                }
                if payRequest.AESKey.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptyAESKey
                }
                if payRequest.TxnRefNo.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptyTxnRefNo
                }
            }
            
        }
        else
        {
            if payRequest.SecureSecret.isEmpty
            {
                if self.enableLog {
                    print("SecureSecret is require parameter")
                }
                throw RequestError.emptySecureSecret
            }
            if payRequest.AESKey.isEmpty
            {
                if self.enableLog {
                    print("AESKey is require parameter")
                }
                throw RequestError.emptyAESKey
            }
            if payRequest.TxnRefNo.isEmpty
            {
                if self.enableLog {
                    print("TxnRefNo is require parameter")
                }
                throw RequestError.emptyTxnRefNo
            }
        }
        
        
    }
    
    func validateRequest(request:ISGUpiStatusRequest) throws
    {
        
        if let encData = request.encData
        {
            if !encData.isEmpty
            {
                return;
            }
        }
        
        
        if request.Environment.isEmpty
        {
            if self.enableLog {
                print("Environment is require parameter")
            }
            throw RequestError.emptyEnvironment
        }
        if request.SecureSecret.isEmpty
        {
            if self.enableLog {
                print("SecureSecret is require parameter")
            }
            throw RequestError.emptySecureSecret
        }
        if request.AESKey.isEmpty
        {
            if self.enableLog {
                print("AESKey is require parameter")
            }
            throw RequestError.emptyAESKey
        }
        if request.BankId.isEmpty
        {
            if self.enableLog {
                print("BankId is require parameter")
            }
            throw RequestError.emptyBankId
        }
        if request.MerchantId.isEmpty
        {
            if self.enableLog {
                print("MerchantId is require parameter")
            }
            throw RequestError.emptyMerchantId
        }
        if request.TerminalId.isEmpty
        {
            if self.enableLog {
                print("TerminalId is require parameter")
            }
            throw RequestError.emptyTerminalId
        }
        if request.OrderId.isEmpty
        {
            if self.enableLog {
                print("OrderId is require parameter")
            }
            throw RequestError.emptyOrderId
        }
        if request.AccessCode.isEmpty
        {
            if self.enableLog {
                print("AccessCode is require parameter")
            }
            throw RequestError.emptyAccessCode
        }
        if request.TxnType.isEmpty
        {
            if self.enableLog {
                print("TxnType is require parameter")
            }
            throw RequestError.emptyTxnType
        }
//                if request.SecureHash.isEmpty
//                {
//                    if self.enableLog {
//                        print("SecureHash is require parameter")
//                    }
//                    throw RequestError.emptySecureHash
        
//                }
        
        
    }
    
    private static func validateUpiStatusRequest(request:ISGUpiStatusRequest, isServerProcessEncData:Bool, enableLog:Bool = false) throws
    {
        
        if isServerProcessEncData == false
        {
            
            if request.SecureSecret?.isEmpty ?? false
            {
                if enableLog {
                    print("SecureSecret is require parameter")
                }
                throw RequestError.emptySecureSecret
            }
            if request.AESKey?.isEmpty ?? false
            {
                if enableLog {
                    print("AESKey is require parameter")
                }
                throw RequestError.emptyAESKey
            }
            
            if request.AccessCode?.isEmpty ?? false
            {
                if enableLog {
                    print("AccessCode is require parameter")
                }
                throw RequestError.emptyAccessCode
            }
            if request.TxnType?.isEmpty ?? false
            {
                if enableLog {
                    print("TxnType is require parameter")
                }
                throw RequestError.emptyTxnType
            }
            
        }
        
        
        if request.Environment == nil || request.Environment?.isEmpty ?? false
        {
            if enableLog {
                print("Environment is require parameter")
            }
            throw RequestError.emptyEnvironment
        }
        
        if request.BankId?.isEmpty ?? false
        {
            if enableLog {
                print("BankId is require parameter")
            }
            throw RequestError.emptyBankId
        }
        if request.MerchantId?.isEmpty ?? false
        {
            if enableLog {
                print("MerchantId is require parameter")
            }
            throw RequestError.emptyMerchantId
        }
        if request.TerminalId?.isEmpty ?? false
        {
            if enableLog {
                print("TerminalId is require parameter")
            }
            throw RequestError.emptyTerminalId
        }
        if request.OrderId?.isEmpty ?? false
        {
            if enableLog {
                print("OrderId is require parameter")
            }
            throw RequestError.emptyOrderId
        }
        
//                if request.SecureHash.isEmpty
//                {
//                    if self.enableLog {
//                        print("SecureHash is require parameter")
//                    }
//                    throw RequestError.emptySecureHash
        
//                }
        
        
    }
    
    func validateUPIRequest(payRequest:ISGUpiPayRequest) throws
    {
        
        if let encData = payRequest.encData
        {
            if encData.isEmpty
            {
                if payRequest.SecureSecret.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptySecureSecret
                }
                if payRequest.AESKey.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptyAESKey
                }
                if payRequest.OrderId.isEmpty
                {
                    if self.enableLog {
                        print("SecureSecret is require parameter")
                    }
                    throw RequestError.emptyTxnRefNo
                }
            }
            
        }
        else
        {
            if payRequest.SecureSecret.isEmpty
            {
                if self.enableLog {
                    print("SecureSecret is require parameter")
                }
                throw RequestError.emptySecureSecret
            }
            if payRequest.AESKey.isEmpty
            {
                if self.enableLog {
                    print("AESKey is require parameter")
                }
                throw RequestError.emptyAESKey
            }
            if payRequest.OrderId.isEmpty
            {
                if self.enableLog {
                    print("TxnRefNo is require parameter")
                }
                throw RequestError.emptyTxnRefNo
            }
        }
        
        
    }
    
    func sorterForFileIDASC(this:String, that:String) -> Bool {
        switch this.compare(that, options: .diacriticInsensitive)
        {
        case .orderedAscending:
            //            return false
            return true
        case .orderedDescending:
            //            return true
            return false
        default:
            return true
        }
        //return this.compare(that)//this > that
    }
    
    
    public func decryptEncData(strEncData:String, aesKey:String) -> [String:String]
    {
        var resultData = [String:String]()
        //NSString* strServerData = strEncData;
        let strAESInputBeforDecryption = strEncData.removingPercentEncoding
        
        let strAESInputAfterDecryption = ISGCryptography.decryptedString(strAESInputBeforDecryption, withKey: aesKey)
        
        //NSLog(strAESInputAfterDecryption, nil);
        
        if let arrEncElement = strAESInputAfterDecryption?.components(separatedBy: "::")
        {
            for strElement in arrEncElement {
                let elts = strElement.components(separatedBy: "||")
                if(elts.count >= 2)
                {
                    if let tempKey = elts.first, let tempValue = elts.last
                    {
                        if tempValue != "NULL"
                        {
                            resultData[tempKey] = tempValue.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                        }
                        
                    }
                }
            }
        }
        resultData["calculatedResponseSecureHash"] = self.getResponseSecureHash(dict: resultData)
        return resultData
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        
        activityIndicator.center = self.view.center
        if #available(iOS 13.0, *) {
            activityIndicator.style = UIActivityIndicatorView.Style.large
        }else{
            activityIndicator.style = .whiteLarge
        }
        
        activityIndicator.color = .gray
        activityIndicator.stopAnimating()
        
        lblPleaseWait = UILabel(frame: CGRect(x: 0, y: activityIndicator.frame.maxY, width:self.view.frame.size.width , height: 40))
        lblPleaseWait.textColor = .darkGray
        lblPleaseWait.text = "Please Wait..."
        lblPleaseWait.textAlignment = .center
        lblPleaseWait.isHidden = true
        
        
    }
    
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    
    func sortArray(arr:[String])->[String]
    {
        
        //        return ISGCryptography.sortObjC(arr) as! [String]
        
        var arrData = arr
        arrData.sort()
        return arrData
        
        //        let arrDataResult = arrData.sorted { (lhs: String, rhs: String) -> Bool in
        //            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        //        }
        //        return arrDataResult
    }
    
    
    func encriptionInputStringFrom(dictData:[String:String], hashValue:String) -> String
    {
        var arrKeys = Array(dictData.keys)
        arrKeys = self.sortArray(arr: arrKeys)
        
        var strRawData = ""
        for i in 0..<arrKeys.count {
            let strVal = dictData[arrKeys[i]] ?? "";
            if strVal != ""
            {
                if strRawData != ""
                {
                    strRawData = strRawData + "::"
                }
                let strKeyValue = arrKeys[i] + "||" + strVal
                strRawData = strRawData + strKeyValue
            }
        }
        
        strRawData = strRawData + "::"
        let strKeyValue = "SecureHash" + "||" + hashValue
        strRawData = strRawData + strKeyValue
        
        return strRawData
    }
    
    static func upiEncriptionInputStringFrom(dictData:[String:String], hashValue:String) -> String
    {
        
        var dic = dictData
        dic["SecureHash"] = hashValue
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(dic) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        }
        return ""
    }
    
    func apiCallWithEncriptedValue(strEncValue:String, transactionObj:[String:String], strEnvironment:String, baseURL:String)
    {
        
        var reqURL = URL(string: Constant.kRequestURLActionUAT)
        
        if strEnvironment.uppercased() == "PROD"
        {
            reqURL = URL(string: Constant.kRequestURLActionPROD)
            print("*****####*** ISG PRODUCTION PG FRAMEWORK ***####****")
        }
        else
        {
            print("*****####*** ISG UAT PG FRAMEWORK ***####****")
        }
        
        if let tempURL = URL(string: baseURL)
        {
            reqURL = tempURL
        }
        else
        {
            print("*****####*** DEFAULT BASE URL ***####****")
        }
        
        guard let tReqURL = reqURL else {
            print("*****####*** URL ISSUE ***####****")
            return
        }
        
        
        //        var config = URLSessionConfiguration.default
        //        var header = [String:String]()
        //        header["Accept"] = "application/json"
        //        header["X-Application"] = "<AppKey>"
        //        header["Content-Type"] = "application/x-www-form-urlencoded"
        //        config.httpAdditionalHeaders = header
        
        //        let sessionConfiguration = URLSessionConfiguration.default
        //        var session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let params = self.requestDataWithEncriptedValue(strEncValue: strEncValue, transactionObj: transactionObj)
        
        var request = URLRequest(url: tReqURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = self.httpBodyForParamsDictionary(paramDictionary: params)
        
        if #available(iOS 12.0, *) {
            // Use iOS 11 APIs.
            wkWebView.load(request)
            
        } else {
            // Alternative code for earlier versions of iOS.
            webViewForServerTransaction.loadRequest(request)
        }
        return;
        
    }
    
    
    func UPIApiCallWithEncriptedValue(strEncValue:String, transactionObj:[String:String], strEnvironment:String, baseURL:String)
    {
        
        var reqURL = URL(string: Constant.kRequestURLUPIUAT)
        
        if strEnvironment.uppercased() == "PROD"
        {
            reqURL = URL(string: Constant.kRequestURLUPI)
            print("*****####*** ISG UPI PRODUCTION PG FRAMEWORK ***####****")
        }
        else
        {
            print("*****####*** ISG UPI UAT PG FRAMEWORK ***####****")
        }
        
        if let tempURL = URL(string: baseURL)
        {
            reqURL = tempURL
        }
        else
        {
            print("*****####*** DEFAULT BASE URL ***####****")
        }
        
        guard let tReqURL = reqURL else {
            print("*****####*** UPI URL ISSUE ***####****")
            return
        }
        
        
        //        var config = URLSessionConfiguration.default
        //        var header = [String:String]()
        //        header["Accept"] = "application/json"
        //        header["X-Application"] = "<AppKey>"
        //        header["Content-Type"] = "application/x-www-form-urlencoded"
        //        config.httpAdditionalHeaders = header
        
        //        let sessionConfiguration = URLSessionConfiguration.default
        //        var session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        
        let params = ISGPayController.upiRequestDataWithEncriptedValue(strEncValue: strEncValue, transactionObj: transactionObj)
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params)
        
        if let temp = jsonData, let string = String(data: temp, encoding: String.Encoding.utf8) {
            if self.enableLog
            {
                
                print(string)
            }
        }
        
        var request = URLRequest(url: tReqURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.lblPleaseWait.isHidden = true
            }
            
            guard let data = data, error == nil else {
                if self.enableLog
                {
                    
                    print(error?.localizedDescription ?? "No data")
                }
                self.delegate?.didFailWithError(error: error)
                DispatchQueue.main.async {
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                }
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            
            if let string = String(data: data, encoding: String.Encoding.utf8) {
                if self.enableLog
                {
                    
                    print(string)
                }
            }
            
            if let responseJSON = responseJSON as? [String: Any] {
                if self.enableLog
                {
                    
                    print(responseJSON)
                }
                self.processUPIResponse(resp: responseJSON)
            }
        }
        
        task.resume()
        
        
        //        if #available(iOS 12.0, *) {
        //            // Use iOS 11 APIs.
        //            wkWebView.load(request)
        //
        //        } else {
        //            // Alternative code for earlier versions of iOS.
        //            webViewForServerTransaction.loadRequest(request)
        //        }
        return;
        
    }
    
    func processUPIResponse(resp:[String: Any])
    {
        
        var upiResponse:ISGUpiPayResponse!
        
        do {
            upiResponse = try JSONDecoder().decode(ISGUpiPayResponse.self, from: JSONSerialization.data(withJSONObject: resp))
            if let tempUpiResponse = upiResponse, let errorCode = tempUpiResponse.errorCode, let errorMessage = tempUpiResponse.errorMessage
            {
                
                if errorCode == "00"
                {
                    if let tempResEncData = tempUpiResponse.encData
                    {
                        
                        do {
                            
                            let resEncData = ISGCryptography.decryptedString(tempResEncData, withKey: self.payUpiReqObj.AESKey) ?? ""
                            
                            let data = resEncData.data(using: .utf8)
                            
                            if let jsonArray = try JSONSerialization.jsonObject(with: data!, options : .allowFragments) as? [String:Any]
                            {
                                if self.enableLog
                                {
                                    
                                    print(jsonArray) // use the json here
                                }
                                if let tempUPIURLString = jsonArray["UPIIntentURL"] as? String, let tempUPIURL = URL(string: tempUPIURLString)
                                {
                                    
                                    DispatchQueue.main.async {
                                        if UIApplication.shared.canOpenURL(tempUPIURL)
                                        {
                                            if #available(iOS 10, *) {
                                                UIApplication.shared.open(tempUPIURL, options: [:]) { status in
                                                    
                                                    print(status)
                                                    NotificationCenter.default.addObserver(self, selector: #selector(ISGPayController.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

                                                    
                                                }
                                                
                                            } else {
                                                //UIApplication.shared.openURL(tempUPIURL)
                                                UIApplication.shared.open(tempUPIURL, options: [:]) { status in
                                                    
                                                    print(status)
                                                    NotificationCenter.default.addObserver(self, selector: #selector(ISGPayController.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

                                                    
                                                }
                                                
                                                
                                            }
                                            
                                            self.delegate?.didFinishPaymentWithData(response: jsonArray)
//                                            self.view.removeFromSuperview()
//                                            self.removeFromParent()
                                            
                                            
                                            
                                        }
                                        else
                                        {
                                            let error = NSError(domain: "UPI", code: 901, userInfo: [ "errorCode": "901", "errorMessage": "Make sure the UPI Application is installed on your device", NSLocalizedDescriptionKey: "Make sure the UPI Application is installed on your device"])
                                            self.delegate?.didFailWithError(error: error)
                                            
                                            self.view.removeFromSuperview()
                                            self.removeFromParent()
                                            
                                        }
                                    }
                                    return;
                                }
                            } else {
                                if self.enableLog
                                {
                                    print("bad json")
                                }
                                let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
                                self.delegate?.didFailWithError(error: error)
                                DispatchQueue.main.async {
                                    self.view.removeFromSuperview()
                                    self.removeFromParent()
                                }
                                return;
                            }
                        } catch let error as NSError {
                            if self.enableLog
                            {
                                
                                print(error)
                            }
                            let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
                            self.delegate?.didFailWithError(error: error)
                            DispatchQueue.main.async {
                                self.view.removeFromSuperview()
                                self.removeFromParent()
                            }
                            return;
                        }
                    }
                }
                else
                {
                    var msg = (errorMessage == "") ? "Something went wrong" : errorMessage
                    let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": errorCode, "errorMessage":msg, NSLocalizedDescriptionKey: msg])
                    self.delegate?.didFailWithError(error: error)
                    DispatchQueue.main.async {
                        self.view.removeFromSuperview()
                        self.removeFromParent()
                    }
                    return;
                }
                
                let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
                self.delegate?.didFailWithError(error: error)
                DispatchQueue.main.async {
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                }
                return;
                
            }
            else
            {
                let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
                self.delegate?.didFailWithError(error: error)
                DispatchQueue.main.async {
                    self.view.removeFromSuperview()
                    self.removeFromParent()
                }
                return;
            }
        } catch let error as NSError {
            if self.enableLog
            {
                print(error.localizedDescription)
            }
            let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
            self.delegate?.didFailWithError(error: error)
            DispatchQueue.main.async {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
            return
        }
        
        
        let error = NSError(domain: "UPI", code: 999, userInfo: [ "errorCode": "999", "errorMessage": "Something went wrong", NSLocalizedDescriptionKey: "Something went wrong"])
        self.delegate?.didFailWithError(error: error)
        DispatchQueue.main.async {
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
        return;
        
        
        
    }
    
    
    @objc func didBecomeActive() {
        if self.enableLog
        {
            print("didBecomeActive - App recived control after UPI flow")
            print("implement call back - didFinishWithUPI")
        }
        self.delegate?.didFinishWithUPI?()
        NotificationCenter.default.removeObserver(self)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
    deinit {
        
     }
    
    func requestDataWithEncriptedValue(strEncValue:String, transactionObj:[String:String]) -> [String:String]
    {
        var dictReq = [String:String]()
        dictReq["EncData"] = strEncValue
        
        if let tempValue = transactionObj["MerchantId"]
        {
            if tempValue != ""
            {
                dictReq["MerchantId"] = tempValue
            }
        }
        if let tempValue = transactionObj["TerminalId"]
        {
            if tempValue != ""
            {
                dictReq["TerminalId"] = tempValue
            }
        }
        if let tempValue = transactionObj["BankId"]
        {
            if tempValue != ""
            {
                dictReq["BankId"] = tempValue
            }
        }
        
        if let tempValue = transactionObj["OrderId"]
        {
            if tempValue != ""
            {
                dictReq["OrderId"] = tempValue
            }
        }
        
        //        let arrParams = ["MerchantId", "TerminalId",  "BankId"]
        //        for key in arrParams {
        //            if let tempValue = transactionObj[key]
        //            {
        //                if tempValue != ""
        //                {
        //                    dictReq[key] = tempValue
        //                }
        //            }
        //        }
        
        return dictReq;
    }
    
    
    static func upiRequestDataWithEncriptedValue(strEncValue:String, transactionObj:[String:String]) -> [String:String]
       {
           var dictReq = [String:String]()
           dictReq["encData"] = strEncValue
           
           if let tempValue = transactionObj["MerchantId"]
           {
               if tempValue != ""
               {
                   dictReq["merchantId"] = tempValue
               }
           }
           if let tempValue = transactionObj["TerminalId"]
           {
               if tempValue != ""
               {
                   dictReq["terminalId"] = tempValue
               }
           }
           if let tempValue = transactionObj["BankId"]
           {
               if tempValue != ""
               {
                   dictReq["bankId"] = tempValue
               }
           }
           
           if let tempValue = transactionObj["OrderId"]
           {
               if tempValue != ""
               {
                   dictReq["orderId"] = tempValue
               }
           }
           
           //        let arrParams = ["MerchantId", "TerminalId",  "BankId"]
           //        for key in arrParams {
           //            if let tempValue = transactionObj[key]
           //            {
           //                if tempValue != ""
           //                {
           //                    dictReq[key] = tempValue
           //                }
           //            }
           //        }
           
           return dictReq;
       }
    
    
    func httpBodyForParamsDictionary(paramDictionary:[String:String]) -> Data?
    {
        var parameterArray = [String]();
        
        for (key, value) in paramDictionary
        {
            let param = "\(key)=\(self.percentEscapeString(string: value))"
            parameterArray.append(param)
        }
        
        let strParam = parameterArray.joined(separator: "&")
        
        
        return strParam.data(using: .utf8)
        
        
    }
    
    func percentEscapeString(string:String)-> String
    {
        
        //"=\"#%/<>?@\\^`{|}"
        let customAllowedSet =  NSCharacterSet(charactersIn: ":/?@!$&'()*+,;=").inverted
        var result = string.addingPercentEncoding(withAllowedCharacters: customAllowedSet) ?? ""
        
        result = result.replacingOccurrences(of: " ", with: "+")
        //let result = string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        
        return result
        
    }
    
    func getResponseSecureHash(dict:[String:String]) -> String
    {
        var arrKeys = Array(dict.keys)
        arrKeys = self.sortArray(arr: arrKeys)
        var strHastRawData = self.payReqObj.SecureSecret ?? ""
        for i in 0..<arrKeys.count {
            if arrKeys[i].uppercased() != "SecureHash".uppercased() //ignore SecureHash in response
            {
                if let value = dict[arrKeys[i]]
                {
                    if value != "" {
                        strHastRawData = strHastRawData + value
                    }
                }
            }
        }
        
        let secureHash = ISGCryptography.sha256Hash(for: strHastRawData) ?? ""
        //NSLog(SecureHash, nil);
        //        NSString *responseSecureHash = [dict valueForKey:@"SecureHash"];
        //NSLog(responseSecureHash, nil);
        
        
        return secureHash;
    }
    
    
}


extension String
{
    func compare(object:String) -> ComparisonResult
    {
        if ( self < object )
        {
            return .orderedDescending
        }
        else if ( self.count == object.count )
        {
            return .orderedSame
        }
        
        return .orderedAscending
    }
}


extension ISGPayController: UIWebViewDelegate, URLSessionDelegate
{
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        
        
        if request.url?.scheme == "mobile" {
            var responseParams = [String:String]()
            
            if let query = request.url?.query
            {
                let arrQuery = query.components(separatedBy: "&")
                for item in arrQuery {
                    let elts = item.components(separatedBy: "=")
                    if(elts.count >= 2)
                    {
                        if let tempKey = elts.first, let tempValue = elts.last
                        {
                            responseParams[tempKey] = tempValue
                        }
                    }
                }
            }
            
            
            
            var dictResponseData = [String:String]()
//            transactionResponse = ISGPayResponse()
            
            
            
            if self.isServerProcessed == true
            {
                dictResponseData = responseParams
            }
            else
            {
                //decrypt EncData
                if let strEncData = responseParams["EncData"]
                {
                    if strEncData != "" {
                        
                        dictResponseData = self.decryptEncData(strEncData: strEncData, aesKey: self.payReqObj.AESKey)
                        
                    }
                }
            }
            
            
//            transactionResponse.calculatedResponseSecureHash = dictResponseData["calculatedResponseSecureHash"] ?? ""
//            transactionResponse.amount = dictResponseData["Amount"] ?? ""
//            transactionResponse.authCode = dictResponseData["AuthCode"] ?? ""
//            transactionResponse.cardType = dictResponseData["CardType"] ?? ""
//            transactionResponse.merchantId = dictResponseData["MerchantId"] ?? ""
//            transactionResponse.merchantReferenceCode = dictResponseData["merchantReferenceCode"] ?? ""
//            transactionResponse.message = dictResponseData["Message"] ?? ""
//            transactionResponse.receiptNumber = dictResponseData["receiptNumber"] ?? ""
//            transactionResponse.requestId = dictResponseData["requestID"] ?? ""
//            transactionResponse.responseCode = dictResponseData["ResponseCode"] ?? ""
//            transactionResponse.retRefNo = dictResponseData["RetRefNo"] ?? ""
//            transactionResponse.secureHash = dictResponseData["SecureHash"] ?? ""
//            transactionResponse.terminalId = dictResponseData["TerminalId"] ?? ""
//            transactionResponse.txnRefNo = dictResponseData["TxnRefNo"] ?? ""
//            transactionResponse.bankId = dictResponseData["BankId"] ?? ""
//            transactionResponse.orderInfo = dictResponseData["OrderInfo"] ?? ""
            
            
            webViewForServerTransaction.isHidden = true;
            self.delegate?.didFinishPaymentWithData(response: dictResponseData)
            self.view.removeFromSuperview()
            self.removeFromParent()
            
            return false
        }
        
        
        return true
    }
    
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
        
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        self.webViewForServerTransaction.isHidden = false
        self.activityIndicator.stopAnimating()
        self.lblPleaseWait.isHidden = true
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.delegate?.didFailWithError(error: error)
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.lblPleaseWait.isHidden = true
            self.webViewForServerTransaction.isHidden = true
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
        
        
    }
    
    
}



extension ISGPayController: WKNavigationDelegate, WKUIDelegate
{
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        
        if self.enableLog
        {
            print("URL-->>\(navigationAction.request.url?.absoluteString)")
        }
//        if let temp = navigationAction.request.url?.absoluteString
//        {
//            if temp.contains("commontxnReturn")
//            {
//                let error = NSError(domain: "PG", code: 999, userInfo: [ NSLocalizedDescriptionKey: "Something went wrong"])
//                let alert = UIAlertController(title: "Error", message: error.localizedDescription + "(\(error.code))", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
//                    self.wkWebView.isHidden = true;
//                    self.delegate?.didFailWithError(error: error)
//                    self.view.removeFromSuperview()
//                    self.removeFromParent()
//
//                }))
//                self.present(alert, animated: true, completion: nil)
//                decisionHandler(.cancel)
//                return;
//            }
//        }
        if navigationAction.request.url?.scheme == "mobile"
        {
            // Dismiss the view controller, continue loading the app, etc.
            
            var responseParams = [String:String]()
            
            
            
            if let query = navigationAction.request.url?.query
            {
                let arrQuery = query.components(separatedBy: "&")
                for item in arrQuery {
                    let elts = item.components(separatedBy: "=")
                    if(elts.count >= 2)
                    {
                        if let tempKey = elts.first, let tempValue = elts.last
                        {
                            responseParams[tempKey] = tempValue
                        }
                    }
                }
            }
            
            if responseParams["EncData"] == nil
            {
             
                if let queryData = navigationAction.request.httpBody, let query = String(data: queryData, encoding: String.Encoding.utf8)
                {
                    let arrQuery = query.components(separatedBy: "&")
                    for item in arrQuery {
                        let elts = item.components(separatedBy: "=")
                        if(elts.count >= 2)
                        {
                            if let tempKey = elts.first, let tempValue = elts.last
                            {
                                responseParams[tempKey] = tempValue
                            }
                        }
                    }
                }
            }
            
            
            var dictResponseData = [String:String]()
//            transactionResponse = ISGPayResponse()
            
            
            if self.isServerProcessed == true
            {
                dictResponseData = responseParams
            }
            else
            {
                //decrypt EncData
                if let strEncData = responseParams["EncData"]
                {
                    if strEncData != "" {
                        
                        dictResponseData = self.decryptEncData(strEncData: strEncData, aesKey: self.payReqObj.AESKey)
                       
                        
                    }
                }
            }
            
            
            
            
            
//            transactionResponse.calculatedResponseSecureHash = dictResponseData["calculatedResponseSecureHash"] ?? ""
//            transactionResponse.amount = dictResponseData["Amount"] ?? ""
//            transactionResponse.authCode = dictResponseData["AuthCode"] ?? ""
//            transactionResponse.cardType = dictResponseData["CardType"] ?? ""
//            transactionResponse.merchantId = dictResponseData["MerchantId"] ?? ""
//            transactionResponse.merchantReferenceCode = dictResponseData["merchantReferenceCode"] ?? ""
//            transactionResponse.message = dictResponseData["Message"] ?? ""
//            transactionResponse.receiptNumber = dictResponseData["receiptNumber"] ?? ""
//            transactionResponse.requestId = dictResponseData["requestID"] ?? ""
//            transactionResponse.responseCode = dictResponseData["ResponseCode"] ?? ""
//            transactionResponse.retRefNo = dictResponseData["RetRefNo"] ?? ""
//            transactionResponse.secureHash = dictResponseData["SecureHash"] ?? ""
//            transactionResponse.terminalId = dictResponseData["TerminalId"] ?? ""
//            transactionResponse.txnRefNo = dictResponseData["TxnRefNo"] ?? ""
//            transactionResponse.bankId = dictResponseData["BankId"] ?? ""
//            transactionResponse.orderInfo = dictResponseData["OrderInfo"] ?? ""
            
            wkWebView.isHidden = true;
            self.delegate?.didFinishPaymentWithData(response: dictResponseData)
            self.view.removeFromSuperview()
            self.removeFromParent()
            
            
            
            //        transactionResponse.EncData = strEncData;
            //        transactionResponse.AddressZip = [responseParams valueForKey:@"addressZip"];
            //        transactionResponse.FirstName = [responseParams valueForKey:@"firstName"];
            //        transactionResponse.LastName = [responseParams valueForKey:@"lastName"];
            //        transactionResponse.MCC = [responseParams valueForKey:@"MCC"];
            
            
            decisionHandler(.cancel)
            
            return;
            
        }
        
        decisionHandler(.allow);
        return;
        
    }
    
    
    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        self.wkWebView.isHidden = false
        self.activityIndicator.stopAnimating()
        self.lblPleaseWait.isHidden = true
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFailWithError(error: error)
        self.handleWebViewOnFail()
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.delegate?.didFailWithError(error: error)
        self.handleWebViewOnFail()
        
    }
    
    
    func handleWebViewOnFail()
    {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.lblPleaseWait.isHidden = true
            self.wkWebView.stopLoading()
            self.wkWebView.navigationDelegate = nil
            self.wkWebView.uiDelegate = nil
            self.wkWebView.isHidden = true
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}
