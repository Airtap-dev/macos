//
//  Resolver.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

class Resolver {
    let apiService: APIServing
    let wsService: WSServing
    let webRTCService: WebRTCServing
    
    let persistenceProvider: PersistenceProviding
    let authProvider: AuthProviding
    let callProvider: CallProviding
    
    let linkHandler: LinkHandling

    init() {
        // Services
        let apiService = APIService()
        let wsService = WSService()
        let webRTCService = WebRTCService()
        
        // Providers
        let persistenceProvider = PersistenceProvider()
        let authProvider = AuthProvider()
        let callProvider = CallProvider(webRTCService: webRTCService, wsService: wsService, persistenceProvider: persistenceProvider)
        
        // Handlers
        let linkHandler = LinkHandler(apiService: apiService, persistenceProvider: persistenceProvider)
        
        self.apiService = apiService
        self.wsService = wsService
        self.webRTCService = webRTCService
        self.persistenceProvider = persistenceProvider
        self.authProvider = authProvider
        self.callProvider = callProvider
        self.linkHandler = linkHandler
    }
    
    // MARK: - For AppDelegate -
    func isAuthorised() -> Bool {
        authProvider.currentAccount() != nil
    }
    
    func start(accountId: Int, token: String) {
        wsService.start(accountId: accountId, token: token)
        apiService.setIdentity(accountId: accountId, token: token)
        callProvider.start(accountId: accountId, token: token)
        persistenceProvider.start()
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
