//
//  ISGUpiPayRequest.swift
//  ISGPayUI
//
//  Created by isg mobile on 19/08/22.
//

import Foundation
import UIKit
//ISGPayUPIIndentRequest
public struct ISGUpiPayRequest {
    
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
    
    
    
   //new upi
    ///Required - Alphanumeric - 1-40 Length
    public var OrderId:String!                       //TxnRefNo
    ///Required - Numeric - 8 Length
    public var AccessCode:String!    //Alphanumeric // PassCode
    ///Required - Alphanumeric - 3-10 Length
    public var Command:String!    //Alphanumeric // TxnType  --> "Pay",
    ///Required - Alphanumeric - 2-40 Length
    public var PaymentOption:String = "upii"    //Alphanumeric  //payOpt --> upii
    
    
    
    ///Required - Numeric - 4 Length
    public var MCC:String!    //Numeric
    ///Required - Numeric - 3 Length
    public var Currency:String!    //Numeric
    ///Required - Numeric - 1-12 Length
    public var Amount:String!    //Numeric
    ///Required - Alphanumeric - 1-40 Length
    public var OrderInfo:String!    //Alphanumeric
    
    
    //Optional
    ///Optional - Alphanumeric - 1-30 Length
    public var chFirstName:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var chLastName:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var chAddrStreet:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var chAddrCity:String!    //Alphabetic
    ///Optional - Alphanumeric - 6 Length
    public var chAddrZip:String!    //Numeric
    ///Optional - Alphanumeric - 1-30 Length
    public var chAddrState:String!    //Alphabetic
    ///Optional - Alphanumeric - 1-30 Length
    public var chEmail:String!    //Alphanumeric
    ///Optional - Alphanumeric - 10 Length
    public var chPhone:String!    //Numeric
    ///Optional - Alphanumeric - 10 Length
    public var IpAddress:String!    //Numeric
    
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
    
    ///Optional - Alphanumeric - 1-500 Length
    public var TransactionNote:String!    //Alphanumeric
    ///Optional - Alphanumeric - 1-500 Length
    public var MerchantReturnURL:String!    //Alphanumeric
    
    
    
//
//                                            ///Required - Alphanumeric - 1-40 Length
//                                            public var TxnRefNo:String!
//
//                                            ///Required - Alphanumeric - 8 Length
//                                            public var PassCode:String!    //Alphanumeric
//                                                ///Required - Alphanumeric - 3-10 Length
//                                                public var TxnType:String!    //Alphabetic
//
//
//
//                                            ///Conditional - Alphanumeric - 2-10 Length
//                                            public var payOpt:String!    //Alphanumeric
    
    
    //ReturnURL     Required added in code --> mobile://processisgpay.ios
    
    ///Required - Alphabet - * Length  e.g. "UAT" or "PROD"
    public var Environment:String!
    ///Required - Numeric - 1-10 Length eg. "1"
//    public var Version:String!
    
    
    ///Optional - String - To use pre-processed data EncData
    public var encData:String?
    
    public init() {}
}
