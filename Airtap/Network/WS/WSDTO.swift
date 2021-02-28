//
//  WSDTO.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

enum WSPayloadType: String, Codable {
    case ack = "ack"
    case offer = "offer"
    case answer = "answer"
    case candidate = "candidate"
}

struct WSPayloadOffer: Codable {
    let sdp: String
}

struct WSPayloadAnswer: Codable {
    let sdp: String
}

struct WSPayloadCandidate: Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}

struct WSPayloadContent: Codable {
    var toAccountId: Int?
    var fromAccountId: Int?
    var offer: WSPayloadOffer?
    var answer: WSPayloadAnswer?
    var candidate: WSPayloadCandidate?
    
    init(
        toAccountId: Int? = nil,
        fromAccountId: Int? = nil,
        offer: WSPayloadOffer? = nil,
        answer: WSPayloadAnswer? = nil,
        candidate: WSPayloadCandidate? = nil
    ) {
        self.toAccountId = toAccountId
        self.fromAccountId = fromAccountId
        self.offer = offer
        self.answer = answer
        self.candidate = candidate
    }
}

struct WSPayload: Codable {
    var type: WSPayloadType
    var nonce: Int
    var payload: WSPayloadContent?
}
