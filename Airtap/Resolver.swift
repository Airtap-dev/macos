//
//  Resolver.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

class Resolver {
    let apiService: APIServing
    let wsService: WSServing
    let webRTCService: WebRTCServing
    
    let authProvider: AuthProviding
    let keyboardProvider: KeyboardProviding
    let persistenceProvider: PersistenceProviding
    let callProvider: CallProviding
    let logProvider: LogProviding
    
    let linkHandler: LinkHandling

    init(authProvider: AuthProviding, logProvider: LogProviding) {
        self.apiService = APIService(authProvider: authProvider, logProvider: logProvider)
        self.webRTCService = WebRTCService(authProvider: authProvider, logProvider: logProvider)
        
        self.logProvider = logProvider
        self.authProvider = authProvider
        self.keyboardProvider = KeyboardProvider()
        self.persistenceProvider = PersistenceProvider(authProvider: authProvider, logProvider: logProvider)
        self.wsService = WSService(authProvider: authProvider, persistenceProvider: persistenceProvider, logProvider: logProvider)
        self.callProvider = CallProvider(
            webRTCService: webRTCService,
            apiService: apiService,
            wsService: wsService,
            authProvider: authProvider,
            persistenceProvider: persistenceProvider,
            keyboardProvider: keyboardProvider,
            logProvider: logProvider
        )
        
        self.linkHandler = LinkHandler(
            authProvider: authProvider,
            apiService: apiService,
            persistenceProvider: persistenceProvider,
            logProvider: logProvider
        )
    }
    
    // MARK: - Routing -
    func welcome() -> WelcomeView {
        let m = WelcomeModel(apiService: apiService, authProvider: authProvider, logProvider: logProvider)
        let vm = WelcomeViewModel(model: m, logProvider: logProvider)
        let v = WelcomeView(viewModel: vm, logProvider: logProvider)
        
        return v
    }
    
    func main() -> MainView {
        let m = MainModel(authProvider: authProvider, callProvider: callProvider, persistenceProvider: persistenceProvider, logProvider: logProvider)
        let vm = MainViewModel(model: m, logProvider: logProvider)
        let v = MainView(viewModel: vm, wireframe: MainWireframe(self), logProvider: logProvider)
        
        return v
    }
}
