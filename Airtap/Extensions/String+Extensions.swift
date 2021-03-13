//
//  String+Extensions.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation

extension String {
    func initials(limit: Int? = nil) -> String {
        let initials = components(separatedBy: " ").map {
            $0.replacingOccurrences(of: "\r\n|\n|\r| ", with: "", options: .regularExpression)
            }.filter {$0 != ""}.map {
                $0.prefix(1).capitalized
            }.reduce("", +)
        
        return limit == nil ? initials : String(initials.prefix(limit!))
    }
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    public func localized(with arguments: [CVarArg]) -> String {
        return String(format: self.localized, locale: nil, arguments: arguments)
    }
}
