//
//  MainModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine

class MainModel: ObservableObject {

    private let authProvider: AuthProviding
    private let callProvider: CallProviding
    private let persistenceProvider: PersistenceProviding
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var peers: [Peer]
    
    init(
        authProvider: AuthProviding,
        callProvider: CallProviding,
        persistenceProvider: PersistenceProviding
    ) {
        self.authProvider = authProvider
        self.callProvider = callProvider
        self.persistenceProvider = persistenceProvider
        
        self.peers = self.persistenceProvider.peers
        self.persistenceProvider.eventSubject
            .sink { [weak self] event in
                switch event {
                case let .peerLoaded(loadedPeer):
                    self?.peers.append(loadedPeer)
                case let .peerUnloaded(unloadedPeer):
                    self?.peers.removeAll(where: { peer -> Bool in
                        peer.id == unloadedPeer.id
                    })
                }
            }
            .store(in: &cancellables)
    }
}
