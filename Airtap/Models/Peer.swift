//
//  Contact.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import RealmSwift

class Peer: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var firstName: String = ""
    @objc dynamic var lastName: String? = nil
    
    override static func primaryKey() -> String? {
        return "id"
    }
}
