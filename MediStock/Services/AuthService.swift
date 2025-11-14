//
//  AuthService.swift
//  MediStock
//
//  Created by Ordinateur elena on 14/11/2025.
//

import Foundation
import FirebaseAuth


class AuthService: AuthServicing {
    static let shared = AuthService()
    private let auth: Auth
    
    private init() {
        auth = Auth.auth()
    }
    
    func listenToAuthStateChanges(completion: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle {
        return auth.addStateDidChangeListener { _, user in //closure sur thread principal
            completion(user)
        }
    }
    
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(nil, error)
            } else if let user = result?.user {
                let appUser = AppUser(uid: user.uid, email: user.email ?? "")
                completion(appUser, nil)
            } else {
                let error = NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Utilisateur introuvable"])
                completion(nil, error)
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (AppUser?, Error?)-> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(nil, error)
            } else {
                let appUser = AppUser(uid: result?.user.uid ?? "", email: result?.user.email ?? "")
                completion(appUser, nil)
            }
        }
    }
    
    func signOut() throws {
       try auth.signOut()
    }
    
    func removeListener(handle: AuthStateDidChangeListenerHandle?) {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}
