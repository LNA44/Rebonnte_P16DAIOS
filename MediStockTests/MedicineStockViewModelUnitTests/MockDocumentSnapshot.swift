//
//  MockDocumentSnapshot.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
@testable import MediStock

class MockDocumentSnapshot: DocumentSnapshotType {
    let id: String
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}

