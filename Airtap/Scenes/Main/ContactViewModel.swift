//
//  ContactViewModel.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 03.03.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation

struct ContactViewModel: Hashable {
    var name: String
    var key: String
    var isMuted: Bool
    
    init(peer: Peer, key: String) {
        self.name = peer.lastName == nil ? peer.firstName : peer.firstName + " " + peer.lastName!
        self.key = key
        self.isMuted = peer.isMuted
    }
}
