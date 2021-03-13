//
//  MainViewModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    private var model: MainModel

    @Published private(set) var shouldShowOnboarding: Bool = false
    @Published private(set) var accountOwnerInitials: String = ""
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
                let accountFullName: String = account.lastName == nil ? account.firstName : account.firstName + " " + account.lastName!
                self?.accountOwnerInitials = accountFullName.initials(limit: 2)
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
            }
            .store(in: &cancellables)
    }
    
    func removePeer(_ index: Int) {
        model.removePeer(index)
    }
}
