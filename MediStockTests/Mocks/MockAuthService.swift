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
    
    var listenerCallback: ((FirebaseAuth.User?) -> Void)?

    // Pour enregistrer si removeListener a été appelé
    var removedHandle: AuthStateDidChangeListenerHandle?

    func signOut() throws {
        if shouldThrowOnSignOut {
            throw NSError(domain: "MockAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign out failed (mock)"])
        }
        // sinon rien -> succès
    }

    func listenToAuthStateChanges(
            completion: @escaping (FirebaseAuth.User?) -> Void
        ) -> AuthStateDidChangeListenerHandle {
            listenerCallback = completion
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

/*extension MockAuthService {
    func simulateAuthStateChange(user: AppUser?) {
        listenerCallback?(user)
    }
}*/

final class MockAuthStateListenerHandle: NSObject {}
