//
//  CallProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine

protocol CallProviding {
    func start(accountId: Int, token: String)
    func addPeer(accountId: Int)
    func removePeer(accountId: Int)
}

class CallProvider: CallProviding {
    
    private let webRTCService: WebRTCServing
    private let wsService: WSServing
    private let persistenceProvider: PersistenceProviding
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        webRTCService: WebRTCServing,
        wsService: WSServing,
        persistenceProvider: PersistenceProviding
    ) {
        self.webRTCService = webRTCService
        self.wsService = wsService
        self.persistenceProvider = persistenceProvider
    }
    
    func start(accountId: Int, token: String) {
        wsService.eventSubject
            .sink { [weak self] event in
                guard let self = self else { return }
                switch(event) {
                case let .receiveOffer(accountId, sdp):
                    self.handleIncomingOffer(accountId: accountId, sdp: sdp)
                case let .receiveAnswer(accountId, sdp):
                    self.handleIncomingAnswer(accountId: accountId, sdp: sdp)
                case let .receiveCandidate(accountId, sdp, sdpMLineIndex, sdpMid):
                    self.handleRemoteCandidate(accountId: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                }
            }
            .store(in: &cancellables)
        
        webRTCService.eventSubject
            .sink { [weak self] event in
                switch event {
                case let .receiveCandidate(accountId, sdp, sdpMLineIndex, sdpMid):
                    self?.handleLocalCandidate(accountId: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                default:break
                }
            }
            .store(in: &cancellables)
        
        persistenceProvider.eventSubject
            .sink { [weak self] event in
                switch(event) {
                case let .peerLoaded(peer):
                    self?.addPeer(accountId: peer.id)
                case let .peerUnloaded(peer):
                    self?.removePeer(accountId: peer.id)
                }
            }
            .store(in: &cancellables)
    }
    
    
    func addPeer(accountId: Int) {
        webRTCService.createConnection(id: accountId)
        webRTCService.createOffer(for: accountId) { [weak self] sdp in
            guard let sdp = sdp else { fatalError() }
            self?.wsService.sendOffer(to: accountId, sdp: sdp)
        }
    }
    
    func removePeer(accountId: Int) {
        webRTCService.closeConnection(id: accountId)
    }
    
    private func handleIncomingOffer(accountId: Int, sdp: String) {
        webRTCService.setOffer(for: accountId, sdp: sdp) { [weak self] in
            self?.webRTCService.createAnswer(for: accountId) { [weak self] sdp in
                guard let sdp = sdp else { fatalError() }
                self?.wsService.sendAnswer(to: accountId, sdp: sdp)
            }
        }
    }
    
    private func handleIncomingAnswer(accountId: Int, sdp: String) {
        webRTCService.setAnswer(for: accountId, sdp: sdp) { [weak self] in
            //no-op
        }
    }
    
    private func handleRemoteCandidate(accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        webRTCService.setCandidate(for: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    private func handleLocalCandidate(accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        wsService.sendCandidate(to: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    
}
