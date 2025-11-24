//
//  MockDocumentSnapshot.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import FirebaseFirestore
@testable import MediStock

struct StubDocumentSnapshot: DocumentSnapshotType, Equatable {
    let id: String = UUID().uuidString 
}
