//
//  FakeAuthServiceWithError.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseAuth
@testable import MediStock


final class FakeAuthServiceWithError: AuthServicing {
    
    func listenToAuthStateChanges(completion: @escaping (AuthUserInfo?) -> Void) -> AuthStateDidChangeListenerHandle {
        completion(nil)
        return FakeAuthStateListenerHandle()
    }
    
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        let error = NSError(domain: "AuthError", code: 17007, userInfo: [
            NSLocalizedDescriptionKey: "Email already in use"
        ])
        completion(nil, error)
    }
    
    func signIn(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        let error = NSError(domain: "AuthError", code: 17009, userInfo: [
            NSLocalizedDescriptionKey: "Wrong password"
        ])
        completion(nil, error)
    }
    
    func signOut() throws {
        throw NSError(domain: "AuthError", code: 1)
    }
    
    func removeListener(handle: AuthStateDidChangeListenerHandle?) {}
}
