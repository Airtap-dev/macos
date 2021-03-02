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

enum PersistenceProviderEvent {
    case peerLoaded(Peer)
    case peerUnloaded(Peer)
}

protocol PersistenceProviding {
    var eventSubject: PassthroughSubject<PersistenceProviderEvent, Never> { get }
    var peers: [Peer] { get }
    
    func start()
    func insertPeer(id: Int, firstName: String, lastName: String?)
    func deletePeer(id: Int)
}

class PersistenceProvider: PersistenceProviding {
    
    private(set) var eventSubject = PassthroughSubject<PersistenceProviderEvent, Never>()
    private(set) var peers: [Peer] = []
    
    private let realm: Realm
    
    init() {
        realm = try! Realm()
        
        //        try! realm.write {
        //            realm.deleteAll()
        //        }
    }
    
    func start() {
        let peers = self.realm.objects(Peer.self)
        self.peers = peers.map { $0 }
        self.peers.forEach {
            self.eventSubject.send(.peerLoaded($0))
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

