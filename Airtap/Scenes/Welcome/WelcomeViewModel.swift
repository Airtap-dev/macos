//
//  WelcomeViewModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI
import Combine

class WelcomeViewModel: ObservableObject {
    
    private let model: WelcomeModel
    
    @Published var licenseKey: String = "ac8a47fc-3a1c-4bfc-8c54-56b1f51ee7dd"
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: WelcomeModel) {
        self.model = model
        
        self.model.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch(event) {
                case .successfullySignedUp:
                    NSApplication.shared.keyWindow?.close()
                case .failedToSignUp:
                    break
                }
            }
            .store(in: &cancellables)
    }
    
    func signUp() {
        model.signUp(
            licenseKey: licenseKey,
            firstName: firstName,
            lastName: lastName.isEmpty ? nil : lastName
        )
    }
}
