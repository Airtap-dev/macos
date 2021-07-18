//
//  WSService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Starscream
import Combine

enum WSServiceEvent: Equatable {
    case ready
    case receiveOffer(fromAccountId: Int, sdp: String)
    case receiveAnswer(fromAccountId: Int, sdp: String)
    case receiveCandidate(fromAccountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
    case receiveInfo(fromAccountId: Int, type: WSPayloadInfoType)
}

protocol WSServing {
    var eventSubject: PassthroughSubject<WSServiceEvent, Never> { get }

    func sendOffer(to accountId: Int, sdp: String)
    func sendAnswer(to accountId: Int, sdp: String)
    func sendCandidate(to accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
    func sendInfo(to accountId: Int, type: WSPayloadInfoType)
}

class WSService: WSServing {
    private let authProvider: AuthProviding
    private let logProvider: LogProviding
    
    private(set) var eventSubject = PassthroughSubject<WSServiceEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
        
    private var authString: String?
    private var socket: WebSocket?
    private var nonce: Int = 0
    
    init(authProvider: AuthProviding, logProvider: LogProviding) {
        self.authProvider = authProvider
        self.logProvider = logProvider
        
        self.authProvider.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case let .signedIn(accountId, token):
                    self?.start(accountId: accountId, token: token)
                case .signedOut:
                    self?.authString = nil
                    self?.socket?.disconnect()
                    self?.socket = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func start(accountId: Int, token: String) {
        if let authString = "\(accountId):\(token)".data(using: .utf8)?.base64EncodedString() {
            self.authString = authString
            connectIfAuthorised()
        }
    }
    
    private func connectIfAuthorised() {
        guard let authString = authString else { return }
        
        var request = URLRequest(url: URL(string: Config.wsEndpoint)!)
        request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 5
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    private func stop() {
        socket?.disconnect()
    }

    func sendOffer(to accountId: Int, sdp: String) {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d sending an offer to account %d", self.authProvider.accountId!, accountId)))
        send(
            type: .offer,
            content: WSPayloadContent(
                toAccountId: accountId,
                offer: WSPayloadOffer(sdp: sdp)
            )
        )
    }
    
    func sendAnswer(to accountId: Int, sdp: String) {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d sending an answer to account %d", self.authProvider.accountId!, accountId)))
        send(
            type: .answer,
            content: WSPayloadContent(
                toAccountId: accountId,
                answer: WSPayloadAnswer(sdp: sdp)
            )
        )
    }
    
    func sendCandidate(to accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d sending a candidate to account %d", self.authProvider.accountId!, accountId)))
        send(
            type: .candidate,
            content: WSPayloadContent(
                toAccountId: accountId,
                candidate: WSPayloadCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
            )
        )
    }
    
    func sendInfo(to accountId: Int, type: WSPayloadInfoType) {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d sending info to account %d", self.authProvider.accountId!, accountId)))
        send(
            type: .info,
            content: WSPayloadContent(
                toAccountId: accountId,
                info: WSPayloadInfo(type: type)
            )
        )
    }
    
    private func sendAck(nonce: Int) {
        self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d sending %d ack", self.authProvider.accountId!, nonce)))
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
        
        print("SOCKETS OUT: \(body)")
        
        socket.write(string: body)
    }
    
    private func handle(_ message: WSPayload) {
        guard let accountId = message.payload?.fromAccountId else { return }
        
        switch(message.type) {
        case .ack:
            self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d received an ack", self.authProvider.accountId!)))
            break
        case .offer:
            self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d received an offer from %d", self.authProvider.accountId!, accountId)))
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
            self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d received an answer from %d", self.authProvider.accountId!, accountId)))
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
            self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d received a candidate from %d", self.authProvider.accountId!, accountId)))
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
        case .info:
            self.logProvider.addLogEntry(entry: LogEntry.init(level: LogLevel.debug, text: String(format: "account %d received info from %d", self.authProvider.accountId!, accountId)))
            if let info = message.payload?.info {
                self.sendAck(nonce: message.nonce)
                self.eventSubject.send(
                    .receiveInfo(
                        fromAccountId: accountId,
                        type: info.type
                    )
                )
            }
        }
    }
}

extension WSService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .disconnected:
            self.connectIfAuthorised()
        case .connected:
            self.eventSubject.send(.ready)
        case let .text(receivedString):
            let payload = try! JSONDecoder().decode(WSPayload.self, from: receivedString.data(using: .utf8)!)
            self.handle(payload)
        default: break
        }
    }
}

