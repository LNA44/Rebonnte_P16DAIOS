//
//  MockAuthService.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseAuth
@testable import MediStock

final class MockAuthService: AuthServicing {

    // Si true, signOut() va thrower pour tester le flux d'erreur
    var shouldThrowOnSignOut = false
    var signUpCalled = false
    var signInCalled = false
    
    var mockUser: AppUser?
    var mockError: Error?

    // Pour enregistrer si removeListener a été appelé
    var removedHandle: AuthStateDidChangeListenerHandle?

    func signOut() throws {
        if shouldThrowOnSignOut {
            throw NSError(domain: "MockAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign out failed (mock)"])
        }
        // sinon rien -> succès
    }

    // Si ton protocole demande une écoute d'auth state:
    func listenToAuthStateChanges(
        completion: @escaping (FirebaseAuth.User?) -> Void
    ) -> AuthStateDidChangeListenerHandle {

        return MockAuthStateListenerHandle()
    }

    func removeListener(handle: AuthStateDidChangeListenerHandle?) {
        removedHandle = handle
    }

    // Optionnel : helper pour simuler un changement d'état depuis le test
    // func simulateAuthStateChange(user: FirebaseAuth.User?) { ... }
    
    func signUp(email: String,
                    password: String,
                    completion: @escaping (AppUser?, Error?) -> Void) {

            signUpCalled = true
            completion(mockUser, mockError)
        }

        func signIn(email: String,
                    password: String,
                    completion: @escaping (AppUser?, Error?) -> Void) {

            signInCalled = true
            completion(mockUser, mockError)
        }
}


final class MockAuthStateListenerHandle: NSObject {}
