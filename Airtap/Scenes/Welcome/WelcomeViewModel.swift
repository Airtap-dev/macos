//
//  WelcomeViewModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import SwiftUI
import Combine

class WelcomeViewModel: ObservableObject {
    
    private let model: WelcomeModel
    
    @Published var licenseKey: String = ""
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
