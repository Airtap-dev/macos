//
//  Server.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 03.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import RealmSwift

class Server: Object {
    @objc dynamic var id: Int = 0
    @objc dynamic var url: String = ""
    @objc dynamic var username: String = ""
    @objc dynamic var password: String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

