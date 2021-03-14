//
//  AuthProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import SwiftUI
import Combine
import KeychainSwift

enum AuthProviderEvent: Equatable {
    case signedIn(Int, String)
    case signedOut
}

protocol AuthProviding {
    var eventSubject: PassthroughSubject<AuthProviderEvent, Never> { get }
    
    var accountId: Int? { get }
    var isAuthorised: Bool { get }
    var isAuthorisedPublished: Published<Bool> { get }
    var isAuthorisedPublisher: Published<Bool>.Publisher { get }
    
    func load()
    func signIn(accountId: Int, token: String)
    func signOut()
}

class AuthProvider: AuthProviding, ObservableObject {
    private let keychain: KeychainSwift

    private(set) var accountId: Int?
    @Published private(set) var isAuthorised: Bool = false
    var isAuthorisedPublished: Published<Bool> { _isAuthorised }
    var isAuthorisedPublisher: Published<Bool>.Publisher { $isAuthorised }
    
    private(set) var eventSubject = PassthroughSubject<AuthProviderEvent, Never>()
    
    init() {
        self.keychain = KeychainSwift()
    }

    func load(){
        if let accountId = keychain.get("accountId"), let token = keychain.get("accountToken") {
            signIn(accountId: Int(accountId)!, token: token)
        }
    }
    
    func signIn(accountId: Int, token: String) {
        keychain.set("\(accountId)", forKey: "accountId")
        keychain.set(token, forKey: "accountToken")
        
        self.accountId = accountId
        self.isAuthorised = true
        eventSubject.send(.signedIn(accountId, token))
    }
    
    func signOut() {
        keychain.delete("accountId")
        keychain.delete("accountToken")
        
        self.accountId = nil
        self.isAuthorised = false
        eventSubject.send(.signedOut)
    }
}
