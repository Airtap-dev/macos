//
//  MainModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Combine

class MainModel {

    private let authProvider: AuthProviding
    private let callProvider: CallProviding
    private let persistenceProvider: PersistenceProviding
    
    init(
        authProvider: AuthProviding,
        callProvider: CallProviding,
        persistenceProvider: PersistenceProviding
    ) {
        self.authProvider = authProvider
        self.callProvider = callProvider
        self.persistenceProvider = persistenceProvider
    }
    
    
    
}
