//
//  KeyboardProvider.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 10.03.2021.
//  Copyright © 2021 Airtap Ltd. All rights reserved.
//

import Foundation
import Combine
import HotKey
import Carbon

enum KeyboardProviderEvent {
    case keyDown(index: Int)
    case keyUp(index: Int)
}

protocol KeyboardProviding {
    var eventSubject: PassthroughSubject<KeyboardProviderEvent, Never> { get }
}

class KeyboardProvider: KeyboardProviding {
    private(set) var eventSubject = PassthroughSubject<KeyboardProviderEvent, Never>()
    
    private var hotKeys: [HotKey] = []
    
    init() {
        let keys: [Key] = [.one, .two, .three, .four, .five, .six]
        
        keys.indices.forEach { [weak self] index in
            let hotKey = HotKey(key: keys[index], modifiers: [.option])
            hotKey.keyDownHandler = { [weak self] in
                self?.eventSubject.send(.keyDown(index: index))
            }
            hotKey.keyUpHandler = { [weak self] in
                self?.eventSubject.send(.keyUp(index: index))
            }
            self?.hotKeys.append(hotKey)
        }
    }
}
