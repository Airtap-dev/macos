//
//  MainModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI
import Combine

class MainModel: ObservableObject {
    private let authProvider: AuthProviding
    private let callProvider: CallProviding
    private let persistenceProvider: PersistenceProviding
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var isAuthorised: Bool = false
    @Published private(set) var account: Account?
    @Published private(set) var peers: [Peer] = []
    
    init(
        authProvider: AuthProviding,
        callProvider: CallProviding,
        persistenceProvider: PersistenceProviding
    ) {
        self.authProvider = authProvider
        self.callProvider = callProvider
        self.persistenceProvider = persistenceProvider
    
        self.authProvider.isAuthorisedPublisher
            .sink { [weak self] isAuthorised in
                self?.isAuthorised = isAuthorised
            }
            .store(in: &cancellables)
        
        self.callProvider.accountPublisher
            .sink { [weak self] account in
                self?.account = account
            }
            .store(in: &cancellables)
        
        self.persistenceProvider.peersPublisher
            .sink { [weak self] peers in
                self?.peers = peers
            }
            .store(in: &cancellables)
    }
    
    func removePeer(_ index: Int) {
        persistenceProvider.deletePeer(id: peers[index].id)
    }
    
    func toggleMutePeer(_ index: Int) {
        callProvider.toggleMutePeer(accountId: peers[index].id)
    }
    
    func copyShareableLink() {
        Analytics.track(.copyLink)
        if let shareableLink = account?.shareableLink {
            let pasteboard = NSPasteboard.general
            pasteboard.declareTypes([.string], owner: nil)
            pasteboard.setString(shareableLink, forType: .string)
        }
    }
}
