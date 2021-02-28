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
    private let backendService: BackendServing
    private let authProvider: AuthProviding
    
    private(set) var eventSubject = PassthroughSubject<WelcomeModelEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(
        backendService: BackendServing,
        authProvider: AuthProviding
    ) {
        self.backendService = backendService
        self.authProvider = authProvider
    }
    
    func signUp(licenseKey: String, firstName: String, lastName: String?) {
        backendService
            .createAccount(licenseKey: licenseKey, firstName: firstName, lastName: lastName)
            .sink(receiveCompletion: { [weak self] completion in
                switch(completion) {
                case let .failure(_): //TODO: Parse error properly
                    self?.eventSubject.send(.failedToSignUp)
                default: break
                }
            }, receiveValue: { [weak self] response in
                self?.authProvider.signIn(
                    accountId: response.accountId,
                    token: response.token
                )
                
                self?.backendService.setIdentity(
                    accountId: response.accountId,
                    token: response.token
                )
                
                self?.eventSubject.send(.successfullySignedUp)
            }).store(in: &cancellables)
    }
}
