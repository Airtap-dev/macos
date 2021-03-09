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
    
    var isAuthorised: Bool { get }
    
    var accountId: Int? { get }
    
    func load()
    func signIn(accountId: Int, token: String)
    func signOut()
}

class AuthProvider: AuthProviding {
    
    private let keychain: KeychainSwift
    
    private(set) var eventSubject = PassthroughSubject<AuthProviderEvent, Never>()
    
    private(set) var accountId: Int?
    
    init() {
        self.keychain = KeychainSwift()
    }
    
    var isAuthorised: Bool {
        if let _ = keychain.get("accountId"), let _ = keychain.get("accountToken") {
            return true
        }
        return false
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
        eventSubject.send(.signedIn(accountId, token))
    }
    
    func signOut() {
        keychain.delete("accountId")
        keychain.delete("accountToken")
        self.accountId = nil
        
        eventSubject.send(.signedOut)
    }
}
