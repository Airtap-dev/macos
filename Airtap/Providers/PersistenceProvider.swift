//
//  PersistenceProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
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
    
    func insertPeer(id: Int, firstName: String, lastName: String?)
    func deletePeer(id: Int)
}

class PersistenceProvider: PersistenceProviding {
    private let authProvider: AuthProviding
    private let realm: Realm
    
    private(set) var eventSubject = PassthroughSubject<PersistenceProviderEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var peers: [Peer] = []

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
        let peers = self.realm.objects(Peer.self)
        self.peers = peers.map { $0 }
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
        DispatchQueue.main.async { [weak self] in
            let peer = Peer()
            peer.id = id
            peer.firstName = firstName
            peer.lastName = lastName
            
            try! self?.realm.write {
                self?.realm.add(peer)
            }
            
            self?.peers.append(peer)
            self?.eventSubject.send(.peerLoaded(peer))
        }
    }
    
    func deletePeer(id: Int) {
        DispatchQueue.main.async { [weak self] in
            if let peer = self?.realm.objects(Peer.self).filter("id == \(id)").first {
                try! self?.realm.write {
                    self?.realm.delete(peer)
                }
                
                self?.peers.removeAll { p -> Bool in
                    p.id == id
                }
                
                self?.eventSubject.send(.peerUnloaded(peer))
            }
        }
    }
    
}

