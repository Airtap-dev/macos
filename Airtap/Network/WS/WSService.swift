//
//  WSService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Starscream
import Combine

enum WSServiceEvent {
    case receiveOffer(fromAccountId: Int, sdp: String)
    case receiveAnswer(fromAccountId: Int, sdp: String)
    case receiveCandidate(fromAccountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
}

protocol WSServing {
    var eventSubject: PassthroughSubject<WSServiceEvent, Never> { get }
    
    func start(accountId: Int, token: String)
    func sendOffer(to accountId: Int, sdp: String)
    func sendAnswer(to accountId: Int, sdp: String)
    func sendCandidate(to accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
}

class WSService: WSServing {
    
    private(set) var eventSubject = PassthroughSubject<WSServiceEvent, Never>()
    
    private var socket: WebSocket?
    private var nonce: Int = 0
    
    init() { }
    
    func start(accountId: Int, token: String) {
        if let authString = "\(accountId):\(token)".data(using: .utf8)?.base64EncodedString() {
            var request = URLRequest(url: URL(string: Config.wsEndpoint)!)
            request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            socket?.delegate = self
            socket?.connect()
        }
    }
    
    func sendOffer(to accountId: Int, sdp: String) {
        send(
            type: .offer,
            content: WSPayloadContent(
                toAccountId: accountId,
                offer: WSPayloadOffer(sdp: sdp)
            )
        )
    }
    
    func sendAnswer(to accountId: Int, sdp: String) {
        send(
            type: .answer,
            content: WSPayloadContent(
                toAccountId: accountId,
                answer: WSPayloadAnswer(sdp: sdp)
            )
        )
    }
    
    func sendCandidate(to accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        send(
            type: .candidate,
            content: WSPayloadContent(
                toAccountId: accountId,
                candidate: WSPayloadCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            )
        )
    }
    
    private func sendAck(nonce: Int) {
        send(type: .ack, nonce: nonce)
    }
    
    private func send(type: WSPayloadType, nonce: Int? = nil, content: WSPayloadContent? = nil) {
        guard let socket = socket else { fatalError("WebSocket isn't initialized with `accountId` & `token`.") }
        
        if nonce == nil {
            self.nonce += 1
        }

        let payload = WSPayload(
            type: type,
            nonce: nonce == nil ? self.nonce : nonce!,
            payload: content
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let bodyData = try! encoder.encode(payload)
        let body = String(data: bodyData, encoding: .utf8)!
        
        socket.write(string: body)
    }
    
    private func handle(_ message: WSPayload) {
        guard let accountId = message.payload?.fromAccountId else { return }
        
        switch(message.type) {
        case .ack:
            break
        case .offer:
            if let offer = message.payload?.offer {
                self.sendAck(nonce: message.nonce)
                self.eventSubject.send(
                    .receiveOffer(
                        fromAccountId: accountId,
                        sdp: offer.sdp
                    )
                )
            }
        case .answer:
            if let answer = message.payload?.answer {
                self.sendAck(nonce: message.nonce)
                self.eventSubject.send(
                    .receiveAnswer(
                        fromAccountId: accountId,
                        sdp: answer.sdp
                    )
                )
            }
        case .candidate:
            if let candidate = message.payload?.candidate {
                self.sendAck(nonce: message.nonce)
                self.eventSubject.send(
                    .receiveCandidate(
                        fromAccountId: accountId,
                        sdp: candidate.sdp,
                        sdpMLineIndex: candidate.sdpMLineIndex,
                        sdpMid: candidate.sdpMid
                    )
                )
            }
        }
    }
}

extension WSService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case let .text(receivedString):
            let payload = try! JSONDecoder().decode(WSPayload.self, from: receivedString.data(using: .utf8)!)
            self.handle(payload)
        default: break
        }
    }
}

