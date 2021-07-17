//
//  PersistenceProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine
import RealmSwift

enum PersistenceProviderEvent: Equatable {
    case ready
    case peerLoaded(Peer)
    case peerUnloaded(Peer)
}

protocol PersistenceProviding {
    var eventSubject: PassthroughSubject<PersistenceProviderEvent, Never> { get }
    
    var peers: [Peer] { get }
    var peersPublished: Published<[Peer]> { get }
    var peersPublisher: Published<[Peer]>.Publisher { get }
    
    func insertPeer(id: Int, firstName: String, lastName: String?)
    func deletePeer(id: Int)
    func markPeerAsSpeaking(for id: Int, isSpeaking: Bool)
    func markPeerAsMuted(for id: Int, isMuted: Bool)
}

class PersistenceProvider: PersistenceProviding, ObservableObject {
    private let authProvider: AuthProviding
    private let realm: Realm
    
    private(set) var eventSubject = PassthroughSubject<PersistenceProviderEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var peers: [Peer] = []
    var peersPublished: Published<[Peer]> { _peers }
    var peersPublisher: Published<[Peer]>.Publisher { $peers }
    
    init(authProvider: AuthProviding) {
        self.authProvider = authProvider
        realm = try! Realm()
        
        self.authProvider.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .signedIn:
                    self?.loadPersistence()
                case .signedOut:
                    self?.destroyPersistence()
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    private func loadPersistence() {
        self.peers = self.realm.objects(PeerDBO.self).map { $0.toPeer() }
        eventSubject.send(.ready)
    }
    
    private func destroyPersistence() {
        self.peers.forEach {
            self.eventSubject.send(.peerUnloaded($0))
        }
        
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    func insertPeer(id: Int, firstName: String, lastName: String?) {
        Analytics.track(.addPeer)
        
        DispatchQueue.main.async { [weak self] in
            if let _ = self?.realm.object(ofType: PeerDBO.self, forPrimaryKey: id) {
                return
            }
            
            let peerDBO = PeerDBO()
            peerDBO.id = id
            peerDBO.firstName = firstName
            peerDBO.lastName = lastName
            
            try! self?.realm.write {
                self?.realm.add(peerDBO)
            }
            
            self?.peers.append(peerDBO.toPeer())
            self?.eventSubject.send(.peerLoaded(peerDBO.toPeer()))
        }
    }
    
    func deletePeer(id: Int) {
        Analytics.track(.deletePeer)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return  }
            if let peerDBO = self.realm.objects(PeerDBO.self).filter("id == \(id)").first {
                try! self.realm.write {
                    self.realm.delete(peerDBO)
                }
                
                if let indexToDelete = self.peers.firstIndex(where: { $0.id == id }) {
                    let peerToDelete = self.peers[indexToDelete]
                    self.peers.remove(at: indexToDelete)
                    self.eventSubject.send(.peerUnloaded(peerToDelete))
                }
            }
        }
    }
    
    func markPeerAsSpeaking(for id: Int, isSpeaking: Bool) {
        if let index = self.peers.firstIndex(where: { $0.id == id }) {
            self.peers[index].isSpeaking = isSpeaking
        }
    }
    
    func markPeerAsMuted(for id: Int, isMuted: Bool) {
        if let index = self.peers.firstIndex(where: { $0.id == id }) {
            Analytics.track(isMuted ? .mutePeer : .unmutePeer)
            self.peers[index].isMuted = isMuted
        }
    }
}

