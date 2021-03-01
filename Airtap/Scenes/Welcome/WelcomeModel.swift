//
//  WelcomeModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine

enum WelcomeModelEvent {
    case successfullySignedUp
    case failedToSignUp
}

class WelcomeModel {
    // Injectables
    private let apiService: APIServing
    private let authProvider: AuthProviding
    
    private(set) var eventSubject = PassthroughSubject<WelcomeModelEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(
        apiService: APIServing,
        authProvider: AuthProviding
    ) {
        self.apiService = apiService
        self.authProvider = authProvider
    }
    
    func signUp(licenseKey: String, firstName: String, lastName: String?) {
        apiService
            .createAccount(licenseKey: licenseKey, firstName: firstName, lastName: lastName)
            .sink(receiveCompletion: { [weak self] completion in
                switch(completion) {
                case .failure: //TODO: Parse error properly
                    self?.eventSubject.send(.failedToSignUp)
                default: break
                }
            }, receiveValue: { [weak self] response in
                
                print("LINK:")
                
                self?.authProvider.signIn(
                    accountId: response.accountId,
                    token: response.token
                )
                self?.eventSubject.send(.successfullySignedUp)
            }).store(in: &cancellables)
    }
}
