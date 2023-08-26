//
//  ISGPayRequest.swift
//  ISGPayUI
//
//  Created by isg mobile on 11/08/22.
//

import Foundation
import UIKit
//ISGPayUPIIndentRequest
public struct ISGPayRequest {
    
    
    ///Required - Alphanumeric
    public var AESKey:String!
    
    ///Required - Alphanumeric
    public var SecureSecret:String!
    ///Required - Alphanumeric - 6 Length
    public var BankId:String!    //Alphanumeric
    ///Required - Alphanumeric - 16 Length
    public var MerchantId:String!    //Alphanumeric
    ///Required - Alphanumeric - 8 Length
    public var TerminalId:String!    //Alphanumeric
    
    ///Required - Alphanumeric - 1-40 Length
    public var TxnRefNo:String!
    ///Required - Numeric - 4 Length
    public var MCC:String!    //Numeric
    ///Required - Alphanumeric - 8 Length
    public var PassCode:String!    //Alphanumeric
    ///Required - Alphanumeric - 3-10 Length
    public var TxnType:String!    //Alphabetic
    ///Required - Numeric - 3 Length
    public var Currency:String!    //Numeric
    ///Required - Numeric - 1-12 Length
    public var Amount:String!    //Numeric
    ///Required - Alphanumeric - 1-40 Length
    public var OrderInfo:String!    //Alphanumeric
    
    ///Conditional - Alphanumeric - 2-10 Length
    public var payOpt:String!    //Alphanumeric
    
    ///Conditional - Numeric - 13-19 Length
    public var CardNumber:String!    //Numeric
    ///Conditional - Numeric - 6 Length
    public var ExpiryDate:String!    //Numeric
    ///Conditional - Numeric - 3 Length
    public var CardSecurityCode:String!    //Numeric
    ///Conditional - Alphanumeric - 1-6 Length
    public var BankCode:String!    //Alphanumeric
    ///Conditional - Alphabet - 1 Length  e.g. "Y"
    public var chTokenizationConsent:String!    //Alphabet ---> Y
    ///Conditional - Alphanumeric - 1-40 Length
    public var chUserID:String!    //Alphanumeric
    ///Conditional - Alphanumeric - 13-19 Length
    public var CardTokenPan:String!    //Alphanumeric
    ///Conditional - Numeric - 6 Length
    public var CardTokenExpiry:String!    //Numeric
    ///Conditional - Alphanumeric - 1-100 Length
    public var CardTokenCrypto:String!    //Alphanumeric
    ///Conditional - Alphanumeric - 1-50 Length
    public var MerchantTRID :String!    //Alphanumeric
    ///Conditional - Alphanumeric - 1-100 Length
    public var CardTokenReferenceNo:String!    //Alphanumeric
    
    //Optional
    ///Optional - Alphanumeric - 1-30 Length
    public var FirstName:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var LastName:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var Street:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var City:String!    //Alphabetic
    ///Optional - Alphanumeric - 6 Length
    public var ZIP:String!    //Numeric
    ///Optional - Alphanumeric - 1-30 Length
    public var State:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var Email:String!    //Alphanumeric
    ///Optional - Alphanumeric - 10 Length
    public var Phone:String!    //Numeric
    
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF01:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF02:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF03:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF04:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF05:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF06:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF07:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF08:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF09:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var UDF10:String!    //Alphanumeric
    
    //ReturnURL     Required added in code --> mobile://processisgpay.ios
    
    ///Required - Alphabet - * Length  e.g. "UAT" or "PROD"
    public var Environment:String!
    ///Required - Numeric - 1-10 Length eg. "1"
    public var Version:String!
    
//    ///Optional - Boolean - true: To print framwork log
//    public var enableLog:Bool = false
    
    ///Optional - String - To use pre-processed data EncData
    public var encData:String?
    
    public init() {}
}
