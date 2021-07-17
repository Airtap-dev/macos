//
//  WSDTO.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

enum WSPayloadType: String, Codable {
    case ack = "ack"
    case offer = "offer"
    case answer = "answer"
    case candidate = "candidate"
    case info = "info"
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

enum WSPayloadInfoType: String, Codable {
    case micOn = "mic_on"
    case micOff = "mic_off"
}

struct WSPayloadInfo: Codable {
    let type: WSPayloadInfoType
}

struct WSPayloadContent: Codable {
    var toAccountId: Int?
    var fromAccountId: Int?
    var offer: WSPayloadOffer?
    var answer: WSPayloadAnswer?
    var candidate: WSPayloadCandidate?
    var info: WSPayloadInfo?
    
    init(
        toAccountId: Int? = nil,
        fromAccountId: Int? = nil,
        offer: WSPayloadOffer? = nil,
        answer: WSPayloadAnswer? = nil,
        candidate: WSPayloadCandidate? = nil,
        info: WSPayloadInfo? = nil
    ) {
        self.toAccountId = toAccountId
        self.fromAccountId = fromAccountId
        self.offer = offer
        self.answer = answer
        self.candidate = candidate
        self.info = info
    }
}

struct WSPayload: Codable {
    var type: WSPayloadType
    var nonce: Int
    var payload: WSPayloadContent?
}
