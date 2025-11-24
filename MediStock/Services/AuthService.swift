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
    
    func listenToAuthStateChanges(completion: @escaping (AuthUserInfo?) -> Void) -> AuthStateDidChangeListenerHandle {
        return Auth.auth().addStateDidChangeListener { _, user in
                let userInfo = user.map { AuthUserInfo(uid: $0.uid, email: $0.email) }
                completion(userInfo)
            }
    }
    
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(nil, error)
                return
            } 
            guard let user = result?.user else {
                completion(nil, NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Utilisateur introuvable"]))
                return
            }
            
            // Force la création d’un token valide avant que le VM fasse quoi que ce soit pour que le token soit dispo avant la création de l'utilisateur dans firestore
            user.getIDTokenForcingRefresh(true) { _, tokenError in
                if let tokenError = tokenError {
                    completion(nil, tokenError)
                    return
                }
                
                let appUser = AppUser(uid: user.uid, email: user.email ?? "")
                completion(appUser, nil)
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
