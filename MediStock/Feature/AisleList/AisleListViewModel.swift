//
//  AisleListViewModel.swift
//  MediStock
//
//  Created by Ordinateur elena on 20/11/2025.
//

import Foundation
import Firebase

class AisleListViewModel: ObservableObject {
    private let sessionVM: SessionViewModel
    var aislesListener: ListenerRegistration?
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    @Published var aisles: [String] = []
    @Published var appError: AppError?

    init(sessionVM: SessionViewModel, authService: AuthServicing = AuthService.shared, firestoreService: FirestoreServicing = FirestoreService.shared) {
        self.sessionVM = sessionVM
        self.authService = authService
        self.firestoreService = firestoreService
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSignOut), name: .userDidSignOut, object: nil)
    }
    
    @objc private func userDidSignOut() { //arrete les listeners avt destruction du VM pour eviter erreurs firebase qui manque de permissions
        
        aislesListener?.remove()
        aislesListener = nil
    
        print("🔕 Tous les listeners arrêtés suite à la déconnexion")
    }
    
    deinit {
        // ✅ Retire tous les listeners a la suppression du VM
        NotificationCenter.default.removeObserver(self)

        aislesListener?.remove()
        
        print("🧹 Tous les listeners nettoyés")
    }
    
    func fetchAisles() {
        // Retirer l'ancien listener si existant
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
        do {
            try authService.signOut()
            self.sessionVM.session = nil
        } catch let error {
            self.appError = AppError.fromAuth(error)
        }
    }
}
