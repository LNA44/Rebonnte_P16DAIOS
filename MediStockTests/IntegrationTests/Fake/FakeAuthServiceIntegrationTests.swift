//
//  FakeAuthServiceIntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseAuth
@testable import MediStock

final class FakeAuthIntegrationService: AuthServicing {

    // MARK: - State (utile pour les tests)
    var didSignOut = false
    var shouldThrowOnSignOut = false
    
    var lastSignUpEmail: String?
    var lastSignInEmail: String?
    
    var listenerRemoved = false
    private var currentListener: ((AuthUserInfo?) -> Void)?

    // MARK: - listenToAuthStateChanges
    func listenToAuthStateChanges(
            completion: @escaping (AuthUserInfo?) -> Void
        ) -> AuthStateDidChangeListenerHandle {
            // ✅ Stocker le listener au lieu de l'appeler immédiatement
            currentListener = completion
            
            // ✅ Optionnel : simuler un état initial (nil = déconnecté)
            // completion(nil)

            return FakeAuthStateListenerHandle()
        }

    // MARK: - signUp
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        lastSignUpEmail = email
        completion(AppUser(uid: "fakeUID", email: email), nil)
    }

    // MARK: - signIn
    func signIn(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        lastSignInEmail = email
        completion(AppUser(uid: "fakeUID", email: email), nil)
    }

    // MARK: - signOut
    func signOut() throws {
        if shouldThrowOnSignOut {
            throw NSError(domain: "AuthFake", code: 1)
        }
        didSignOut = true
    }

    // MARK: - removeListener
    func removeListener(handle: AuthStateDidChangeListenerHandle?) {
        listenerRemoved = true // ✅ Ajouté
        currentListener = nil
    }
    
    // MARK: - ✅ Helper pour simuler les changements d'état (pour les tests)
    func simulateAuthStateChange(user: (uid: String, email: String)?) {
        if let user = user {
            let authUserInfo = AuthUserInfo(uid: user.uid, email: user.email)
            currentListener?(authUserInfo)
        } else {
            currentListener?(nil)
        }
    }
}

// MARK: - Fake handle
final class FakeAuthStateListenerHandle: NSObject {}
