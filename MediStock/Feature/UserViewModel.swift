//
//  UserViewModel.swift
//  MediStock
//
//  Created by Ordinateur elena on 17/11/2025.
//

//PAS RELIE AU CODE
import Foundation
import FirebaseAuth

@Observable class UserViewModel {
    var email: String = ""
    
    private let authService: AuthService
    private let firestoreService: FirestoreServicing
    
    init(
        authService: AuthService = AuthService.shared,
        firestoreService: FirestoreServicing = FirestoreService.shared,
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
    }

}
