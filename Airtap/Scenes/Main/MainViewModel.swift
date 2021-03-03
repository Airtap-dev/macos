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
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var contactViewModels: [ContactViewModel] = []
    
    init(model: MainModel) {
        model.$peers
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
}
