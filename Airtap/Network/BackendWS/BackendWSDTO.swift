//
//  BackendWSDTO.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

enum BackendWSPayloadType: String, Codable {
    case offer = "offer"
    case answer = "answer"
    case candidate = "candidate"
}

struct BackendWSPayloadContent: Codable {
    var toAccountId: Int?
    var fromAccountId: Int?
    var offer: [String: String]?
    var answer: [String: String]?
    var candidate: [String: String]?
}

struct BackendWSPayload: Codable {
    var type: BackendWSPayloadType
    var nonce: Int
    var payload: BackendWSPayloadContent
}
