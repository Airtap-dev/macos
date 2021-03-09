//
//  Dictionary+Extensions.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 01.03.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

extension Dictionary where Value: Equatable {
    func keyForValue(_ val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}
