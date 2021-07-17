//
//  MainViewModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    private var model: MainModel

    @Published private(set) var shouldShowOnboarding: Bool = false
    @Published private(set) var accountOwnerInitials: String = ""
    @Published private(set) var currentPeerInitials: String = ""
    @Published private(set) var isAccountOwnerSpeaking: Bool = false
    @Published private(set) var currentPeer: Peer?
    @Published private(set) var contactViewModels: [ContactViewModel] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: MainModel) {
        self.model = model
        
        self.model.$isAuthorised
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorised in
                self?.shouldShowOnboarding = !isAuthorised
            }
            .store(in: &cancellables)
        
        self.model.$account
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let account = account else { return }
                
                let accountFullName: String = account.lastName == nil ?
                    account.firstName :
                    account.firstName + " " + account.lastName!
                
                self?.accountOwnerInitials = accountFullName.initials(limit: 2)
                self?.isAccountOwnerSpeaking = account.isSpeaking
            }
            .store(in: &cancellables)
        
        self.model.$peers
            .receive(on: DispatchQueue.main)
            .sink { [weak self] peers in
                var contactsVMs: [ContactViewModel] = []
                peers.indices.forEach {
                    contactsVMs.append(ContactViewModel(peer: peers[$0], key: "\($0 + 1)"))
                }
                self?.contactViewModels = contactsVMs
                
                if let currentPeerIndex = peers.firstIndex(where: { $0.isSpeaking }) {
                    let currentPeer =  peers[currentPeerIndex]
                    
                    let currentPeerFullName: String = currentPeer.lastName == nil ?
                        currentPeer.firstName :
                        currentPeer.firstName + " " + currentPeer.lastName!
                    
                    self?.currentPeer = currentPeer
                    self?.currentPeerInitials = currentPeerFullName.initials(limit: 2)
                } else {
                    self?.currentPeer = nil
                    self?.currentPeerInitials = ""
                }
            }
            .store(in: &cancellables)
    }
    
    func removePeer(_ index: Int) {
        model.removePeer(index)
    }
    
    func toggleMutePeer(_ index: Int) {
        model.toggleMutePeer(index)
    }
    
    func copyShareableLink() {
        model.copyShareableLink()
    }
    
}
