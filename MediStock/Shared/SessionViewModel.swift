import Foundation
import Firebase

class SessionViewModel: ObservableObject {
    static let shared = SessionViewModel()

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
        handle = authService.listenToAuthStateChanges { [weak self] userInfo in
            guard let self = self else { return }

            Task { @MainActor [weak self] in
                if let userInfo = userInfo {
                    self?.session = AppUser(uid: userInfo.uid, email: userInfo.email)
                    print("✅ Utilisateur connecté : \(userInfo.email ?? "sans email")")
                } else {
                    self?.session = nil
                    self?.unbind()
                    print("👤 Utilisateur déconnexion")
                }
            }
        }
    }
    
    func updateSession(user: AppUser?) {
        self.session = user
    }
    
    func unbind() {
        guard handle != nil else { return }
        // VM appelle la fonction du service pour supprimer le listener
        authService.removeListener(handle: handle)
        handle = nil
    }
}
