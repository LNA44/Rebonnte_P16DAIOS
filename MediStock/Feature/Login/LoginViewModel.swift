//
//  LoginViewModel.swift
//  MediStock
//
//  Created by Ordinateur elena on 20/11/2025.
//

import Foundation

class LoginViewModel: ObservableObject {
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    private let sessionVM: SessionViewModel
    
    //MARK: -Initialization
    init(
        authService: AuthServicing = AuthService.shared,
        firestoreService: FirestoreServicing = FirestoreService.shared,
        sessionVM: SessionViewModel
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.sessionVM = sessionVM
    }
    
    func signUp(email: String, password: String, completion: @escaping () -> Void) {
        authService.signUp(email: email, password: password) { [weak self] (user, error) in
            Task {
                if let user = user {
                    guard let self = self else { return }
                    let user = AppUser(uid: user.uid, email: user.email)
                    try await self.firestoreService.createUser(user: user)
                    await MainActor.run {
                        self.sessionVM.updateSession(user: user)
                    }
                } else if let error = error {
                    print("error \(error)")
                }
                completion()
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping () -> Void) {
        authService.signIn(email: email, password: password) { [weak self] (user, error) in
            DispatchQueue.main.async { //ajouté car closure pas forcément sur thread principal
                if let user = user {
                    self?.sessionVM.updateSession(user: AppUser(uid: user.uid, email: user.email))
                } else if let error = error {
                    print("error \(error)")
                }
                completion()
            }
        }
    }
    
}
