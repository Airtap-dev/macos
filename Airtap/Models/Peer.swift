//
//  Contact.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import RealmSwift

struct Peer: Identifiable, Hashable {
    var id: Int
    var firstName: String
    var lastName: String?
    var isSpeaking: Bool = false
}

class PeerDBO: Object, Identifiable {
    @objc dynamic var id: Int = 0
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func toPeer() -> Peer {
        Peer(id: id, firstName: firstName, lastName: lastName)
    }
}
