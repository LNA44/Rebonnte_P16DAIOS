//
//  MockListenerRegistration.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseFirestore
@testable import MediStock

//simule l'objet renvoyé par Firestore quand on ajoute un snapshot listener. L'idée est de vérifier que remove() est appelé (pour vérifier le cleanup des listeners dans ton VM : fetchAisles() doit enlever l'ancien listener, userDidSignOut aussi, et deinit aussi).
final class MockListenerRegistration: NSObject, ListenerRegistration {
    private(set) var removeCallCount = 0
    func remove() {
        removeCallCount += 1
    }
}
