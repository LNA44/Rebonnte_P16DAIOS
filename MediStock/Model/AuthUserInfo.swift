//
//  AuthUser.swift
//  MediStock
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseAuth

struct AuthUserInfo {
    let uid: String
    let email: String?
    
    init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
    
    // Helper pour créer depuis FirebaseAuth.User
    init?(from firebaseUser: User?) {
        guard let user = firebaseUser else { return nil }
        self.uid = user.uid
        self.email = user.email
    }
}
