//
//  Resolver.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

class Resolver {
    let apiService = APIService()
    let wsService = WSService()
    let webRTCService = WebRTCService()
    let persistenceProvider = PersistenceProvider()
    let authProvider = AuthProvider()
    
    let callProvider: CallProviding
    let linkHandler: LinkHandling

    init() {
        self.callProvider = CallProvider(
            webRTCService: webRTCService,
            apiService: apiService,
            wsService: wsService,
            authProvider: authProvider,
            persistenceProvider: persistenceProvider
        )
        
        self.linkHandler = LinkHandler(
            apiService: apiService,
            persistenceProvider: persistenceProvider
        )
    }
    
    // MARK: - For AppDelegate -
    func isAuthorised() -> Bool {
        authProvider.currentAccount() != nil
    }
    
    func start(accountId: Int, token: String) {
        apiService.setIdentity(accountId: accountId, token: token)
        wsService.start(accountId: accountId, token: token)
        
        callProvider.start()
    }
    
    // MARK: - Routing -
    func welcome() -> WelcomeView {
        let m = WelcomeModel(apiService: apiService, authProvider: authProvider)
        let vm = WelcomeViewModel(model: m)
        let v = WelcomeView(viewModel: vm)
        
        return v
    }
    
    func main() -> MainView {
        let m = MainModel(authProvider: authProvider, callProvider: callProvider, persistenceProvider: persistenceProvider)
        let vm = MainViewModel(model: m)
        let v = MainView(viewModel: vm)
        
        return v
    }
}
