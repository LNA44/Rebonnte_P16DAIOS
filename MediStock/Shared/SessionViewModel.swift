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
                        NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                    }
                }
            }
        }
    
    
    func signUp(email: String, password: String, completion: @escaping () -> Void) {
        authService.signUp(email: email, password: password) { [weak self] (user, error) in
            Task {
                if let user = user {
                    guard let self = self else { return }
                    let user = AppUser(uid: user.uid, email: user.email)
                    try await self.firestoreService.createUser(user: user)
                    await MainActor.run {
                        self.session = user
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
                    self?.session = AppUser(uid: user.uid, email: user.email)
                } else if let error = error {
                    print("error \(error)")
                }
                completion()
            }
        }
    }

    func signOut() {
        do {
            try authService.signOut()
            self.session = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func unbind() {
        // VM appelle la fonction du service pour supprimer le listener
        authService.removeListener(handle: handle)
        handle = nil
    }
}
