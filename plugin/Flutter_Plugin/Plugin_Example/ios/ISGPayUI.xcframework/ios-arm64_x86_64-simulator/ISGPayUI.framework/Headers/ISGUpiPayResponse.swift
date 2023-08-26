//
//  ISGUpiPayResponse.swift
//  ISGPayUI
//
//  Created by isg mobile on 19/08/22.
//

import Foundation
public struct ISGUpiPayResponse: Codable {
    let merchantId, terminalId, orderId, pgId: String?
    let bankId, encData, errorCode, errorMessage: String?

    var dictionary: [String: Any] {
        return ["merchantId":merchantId ?? "",
                "terminalId":terminalId ?? "",
                "orderId":orderId ?? "",
                "pgId":pgId ?? "",
                "bankId":bankId ?? "",
                "encData":encData ?? "",
                "errorCode":errorCode ?? "",
                "errorMessage":errorMessage ?? ""]
        }
    
    enum CodingKeys: String, CodingKey {
        case merchantId = "merchantId"
        case terminalId = "terminalId"
        case orderId = "orderId"
        case pgId = "pgId"
        case bankId = "bankId"
        case encData, errorCode, errorMessage
    }
}
