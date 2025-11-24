//
//  FakeSessionViewModelIntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseFirestore
@testable import MediStock

final class FakeSessionViewModel: SessionViewModel {
    init() {
        // On passe des fakes pour auth et firestore
        let fakeAuth = FakeAuthIntegrationService()
        let fakeFirestore = FakeFirestoreIntegrationService()
        super.init(authService: fakeAuth, firestoreService: fakeFirestore)
        
        // On simule un utilisateur connecté
        self.session = AppUser(uid: "123", email: "fake@test.com")
    }
}
