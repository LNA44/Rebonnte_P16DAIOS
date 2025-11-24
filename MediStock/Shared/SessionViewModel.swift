import Foundation
import Firebase

class SessionViewModel: ObservableObject {
    @Published var session: AppUser?
    var handle: AuthStateDidChangeListenerHandle?
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    
    //MARK: -Initialization
    init(
        authService: AuthServicing = AuthService.shared,
        firestoreService: FirestoreServicing = FirestoreService.shared
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
    }
    
    func listen() {
        handle = authService.listenToAuthStateChanges { [weak self] firebaseUser in
            guard let self = self else { return }
            
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    self.session = AppUser(uid: firebaseUser.uid, email: firebaseUser.email)
                    print("✅ Utilisateur connecté : \(firebaseUser.email ?? "sans email")")
                } else {
                    self.session = nil
                    self.unbind() //suppr le listener actuel à la deconnexion
                    print("👤 Utilisateur déconnecté")
                }
            }
        }
    }
    
    func updateSession(user: AppUser?) {
        self.session = user
    }
    
    func unbind() {
        // VM appelle la fonction du service pour supprimer le listener
        authService.removeListener(handle: handle)
        handle = nil
    }
}
