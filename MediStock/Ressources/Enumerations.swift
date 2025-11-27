//
//  Enumerations.swift
//  MediStock
//
//  Created by Ordinateur elena on 10/11/2025.
//

import Foundation

struct Enumerations {
    enum SortOption: String, CaseIterable, Identifiable {
        case none
        case name
        case stock
        
        var id: String { self.rawValue }
    }
}
