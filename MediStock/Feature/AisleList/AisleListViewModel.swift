//
//  AisleListViewModel.swift
//  MediStock
//
//  Created by Ordinateur elena on 20/11/2025.
//

import Foundation
import Firebase

class AisleListViewModel: ObservableObject {
    private weak var sessionVM: SessionViewModel?
    var aislesListener: ListenerRegistration?
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    @Published var aisles: [String] = []
    @Published var appError: AppError?

    init(sessionVM: SessionViewModel? = nil, authService: AuthServicing = AuthService.shared, firestoreService: FirestoreServicing = FirestoreService.shared) {
        self.sessionVM = sessionVM
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    deinit {
        aislesListener?.remove()
    }
    
    func fetchAisles() {
        aislesListener?.remove()
        
        aislesListener = firestoreService.fetchAisles(collection: "medicines") { [weak self] aisles, error in
            guard let self = self else { return }
            if let error = error {
                self.appError = AppError.fromFirestore(error)
                return
            }
            self.appError = nil
            self.aisles = aisles
        }
    }
    
    func signOut() {
        aislesListener?.remove()
        aislesListener = nil
        do {
            try authService.signOut()
            self.sessionVM?.session = nil
        } catch let error {
            self.appError = AppError.fromAuth(error)
        }
    }
}
