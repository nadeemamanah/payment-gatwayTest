//
//  ISGPayResponse.swift
//  ISGPayUI
//
//  Created by isg mobile on 11/08/22.
//

import Foundation

public struct ISGPayResponse {
    
    var amount:String!
    var authCode:String!
    var cardType:String!
    var merchantId:String!
    var merchantReferenceCode:String!
    var message:String!
    var receiptNumber:String!
    var requestId:String!
    var responseCode:String!
    var retRefNo:String!
    var secureHash:String!
    var terminalId:String!
    var txnRefNo:String!
    var bankId:String!
    var orderInfo:String!
    var calculatedResponseSecureHash:String!
    
    var dictionary: [String: Any] {
        return ["amount":amount ?? "",
                "authCode":authCode ?? "",
                "cardType":cardType ?? "",
                "merchantId":merchantId ?? "",
                "merchantReferenceCode":merchantReferenceCode ?? "",
                "message":message ?? "",
                "receiptNumber":receiptNumber ?? "",
                "requestId":requestId ?? "",
                "responseCode":responseCode ?? "",
                "retRefNo":retRefNo ?? "",
                "secureHash":secureHash ?? "",
                "terminalId":terminalId ?? "",
                "txnRefNo":txnRefNo ?? "",
                "bankId":bankId ?? "",
                "orderInfo":orderInfo ?? "",
                "calculatedResponseSecureHash":calculatedResponseSecureHash ?? ""]
        }
}
