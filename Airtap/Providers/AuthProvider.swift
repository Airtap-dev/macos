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

enum AuthProviderEvent {
    case signedIn(Int, String)
    case signedOut
}

protocol AuthProviding {
    var eventSubject: PassthroughSubject<AuthProviderEvent, Never> { get }
    
    func currentAccount() -> (Int, String)?
    func signIn(accountId: Int, token: String)
    func signOut()
}

class AuthProvider: AuthProviding {
    
    private let keychain: KeychainSwift
    
    private(set) var eventSubject = PassthroughSubject<AuthProviderEvent, Never>()
    
    init() {
        self.keychain = KeychainSwift()
    }
    
    func currentAccount() -> (Int, String)? {
        if let accountId = keychain.get("accountId"), let token = keychain.get("accountToken") {
            return (Int(accountId)!, token)
        }
        
        return nil
    }
    
    func signIn(accountId: Int, token: String) {
        keychain.set("\(accountId)", forKey: "accountId")
        keychain.set(token, forKey: "accountToken")
        
        eventSubject.send(.signedIn(accountId, token))
    }
    
    func signOut() {
        keychain.delete("accountId")
        keychain.delete("accountToken")
        
        eventSubject.send(.signedOut)
    }
}
