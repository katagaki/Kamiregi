//
//  Item.swift
//  Kamiregi
//
//  Created by Justin Xin on 2026/05/16.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
