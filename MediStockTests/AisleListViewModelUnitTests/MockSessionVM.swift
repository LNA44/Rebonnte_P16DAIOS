//
//  MockSessionVM.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
@testable import MediStock
import FirebaseFirestore

class MockSessionViewModel: SessionViewModel {
    override init(authService: AuthServicing = AuthService.shared,
                  firestoreService: FirestoreServicing = FirestoreService.shared) {
        super.init(authService: authService, firestoreService: firestoreService)
    }
}
