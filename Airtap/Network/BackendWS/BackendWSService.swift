//
//  BackendWSService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import Starscream


protocol BackendWSServing {
    
}

class BackendWSService: BackendWSServing {
    
    private var socket: WebSocket?
    
    init() { }
    
    func start(accountId: Int, token: String) {
        if let authString = "\(accountId):\(token)".data(using: .utf8)?.base64EncodedString() {
            var request = URLRequest(url: URL(string: Config.wsEndpoint)!)
            request.setValue("Basic \(authString)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 5
            socket = WebSocket(request: request)
            socket?.delegate = self
            socket?.connect()
        }
    }
    
    
    func sendOffer(to accountId: Int) {
    
    }
    
    func sendAnswer(to accountId: Int) {
    
    }
    
    func sendCandidate(to accountId: Int) {
    
    }
    
}

extension BackendWSService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        
    }
}

