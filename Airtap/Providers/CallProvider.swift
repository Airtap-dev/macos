//
//  CallProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine

protocol CallProviding {
    var account: Account? { get }
    var accountPublished: Published<Account?> { get }
    var accountPublisher: Published<Account?>.Publisher { get }
    
    func addPeer(accountId: Int)
    func removePeer(accountId: Int)
    func toggleMutePeer(accountId: Int)
    
    func prepareToQuit()
}

class CallProvider: CallProviding, ObservableObject {
    private let webRTCService: WebRTCServing
    private let apiService: APIServing
    private let wsService: WSServing
    private let authProvider: AuthProviding
    private let persistenceProvider: PersistenceProviding
    private let keyboardProvider: KeyboardProviding
    
    @Published private(set) var account: Account?
    var accountPublished: Published<Account?> { _account }
    var accountPublisher: Published<Account?>.Publisher { $account }
    
    private var dependencyCancellables = Set<AnyCancellable>()
    private var cancellables = Set<AnyCancellable>()
    
    init(
        webRTCService: WebRTCServing,
        apiService: APIServing,
        wsService: WSServing,
        authProvider: AuthProviding,
        persistenceProvider: PersistenceProviding,
        keyboardProvider: KeyboardProviding
    ) {
        self.webRTCService = webRTCService
        self.apiService = apiService
        self.wsService = wsService
        self.authProvider = authProvider
        self.persistenceProvider = persistenceProvider
        self.keyboardProvider = keyboardProvider
        
        Publishers.CombineLatest(
            // Transport
            Publishers.CombineLatest3(
                webRTCService.eventSubject,
                wsService.eventSubject,
                apiService.eventSubject
            ),
            // Local Data
            Publishers.CombineLatest(
                authProvider.eventSubject,
                persistenceProvider.eventSubject
            )
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] (transport, local) in
            let (webRTCEvent, wsEvent, apiEvent) = transport
            let (authEvent, persistenceEvent) = local
            
            if (
                webRTCEvent == .ready &&
                wsEvent == .ready &&
                apiEvent == .identitySet &&
                persistenceEvent == .ready
            ) {
                if case .signedIn(_, _) = authEvent {
                    self?.start()
                }
            }
        })
        .store(in: &cancellables)
        
        apiService.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if case .identitySet = event {
                    self?.startSession()
                }
            }
            .store(in: &cancellables)
        
        authProvider.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if case .signedOut = event {
                    self?.stop()
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
        dependencyCancellables.removeAll()
    }
    
    private func startSession() {
        apiService.startSession()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion, case let .error(code) = error {
                    if APIError(rawValue: code) == .invalidCredentials {
                        self?.authProvider.signOut()
                    }
                }
            }, receiveValue: { [weak self] response in
                self?.account = Account(
                    id: response.accountId,
                    firstName: response.firstName,
                    lastName: response.lastName,
                    shareableLink: response.shareableLink
                )
                self?.webRTCService.setServerList(response.turnCredentials.map {
                    Server(
                        url: $0.url,
                        username: $0.username,
                        password: $0.password
                    )
                })
            }).store(in: &cancellables)
    }
    
    private func start() {
        webRTCService.eventSubject
            .sink { [weak self] event in
                switch event {
                case let .receiveCandidate(accountId, sdp, sdpMLineIndex, sdpMid):
                    self?.handleLocalCandidate(accountId: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
                default: break
                }
            }
            .store(in: &dependencyCancellables)
        
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
                case let .receiveInfo(accountId, type):
                    self.handleRemoteInfo(accountId: accountId, type: type)
                default: break
                }
            }
            .store(in: &dependencyCancellables)
        
        
        persistenceProvider.peers.forEach {
            addPeer(accountId: $0.id)
        }
        
        persistenceProvider.eventSubject
            .sink { [weak self] event in
                switch(event) {
                case let .peerLoaded(peer):
                    self?.addPeer(accountId: peer.id)
                case let .peerUnloaded(peer):
                    self?.removePeer(accountId: peer.id)
                default: break
                }
            }
            .store(in: &dependencyCancellables)
        
        keyboardProvider.eventSubject
            .sink { [weak self] event in
                switch event {
                case let .keyDown(index):
                    if self?.persistenceProvider.peers.indices.contains(index) == true,
                        let peerId = self?.persistenceProvider.peers[index].id {
                        self?.account?.isSpeaking = true
                        self?.wsService.sendInfo(to: peerId, type: .micOn)
                        self?.webRTCService.unmuteMic(id: peerId)
                    }
                case let .keyUp(index):
                    if self?.persistenceProvider.peers.indices.contains(index) == true,
                        let peerId = self?.persistenceProvider.peers[index].id {
                        self?.account?.isSpeaking = false
                        self?.wsService.sendInfo(to: peerId, type: .micOff)
                        self?.webRTCService.muteMic(id: peerId)
                    }
                }
            }
            .store(in: &dependencyCancellables)
    }
    
    private func stop() {
        dependencyCancellables.removeAll()
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
    
    func toggleMutePeer(accountId: Int) {
        if let index = persistenceProvider.peers.firstIndex(where: { $0.id == accountId }) {
            let newValue = !persistenceProvider.peers[index].isMuted
            persistenceProvider.markPeerAsMuted(for: accountId, isMuted: newValue)
            newValue ? webRTCService.muteAudio(id: accountId) : webRTCService.unmuteAudio(id: accountId)
        }
    }
    
    func prepareToQuit() {
        persistenceProvider.peers.forEach {
            webRTCService.closeConnection(id: $0.id)
        }
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
        webRTCService.setAnswer(for: accountId, sdp: sdp) { 
            //no-op
        }
    }
    
    private func handleRemoteCandidate(accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        webRTCService.setCandidate(for: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    private func handleLocalCandidate(accountId: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        wsService.sendCandidate(to: accountId, sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
    
    private func handleRemoteInfo(accountId: Int, type: WSPayloadInfoType) {
        switch type {
        case .micOn:
            persistenceProvider.markPeerAsSpeaking(for: accountId, isSpeaking: true)
        case .micOff:
            persistenceProvider.markPeerAsSpeaking(for: accountId, isSpeaking: false)
        }
    }
    
}
