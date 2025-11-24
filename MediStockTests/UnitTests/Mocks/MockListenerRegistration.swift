//
//  MockListenerRegistration.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
@testable import MediStock

//simule l'objet renvoyé par Firestore quand on ajoute un snapshot listener pour vérifier que remove() est appelé (pour vérifier le cleanup des listeners dans le VM : fetchAisles() doit enlever l'ancien listener, userDidSignOut aussi, et deinit aussi).
final class MockListenerRegistration: MockListenerBase, ListenerRegistration {
    // Hérite removeCallCount et remove() de MockListenerBase
}

final class MockAuthStateListenerHandle: MockListenerBase {
    // Hérite removeCallCount et remove() de MockListenerBase
}

class MockListenerBase: NSObject {
    private(set) var removeCallCount = 0
    
    @objc func remove() {
        removeCallCount += 1
    }
}
