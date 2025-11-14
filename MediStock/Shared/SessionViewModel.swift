import Foundation
import Firebase

class SessionViewModel: ObservableObject {
    @Published var session: AppUser?
    var handle: AuthStateDidChangeListenerHandle?
    let authService: AuthService
    
    //MARK: -Initialization
    init(
        authService: AuthService = AuthService.shared,
    ) {
        self.authService = authService
    }

    /*func listen() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in //closure sur thread principal
            if let user = user {
                self?.session = AppUser(uid: user.uid, email: user.email)
            } else {
                self?.session = nil
            }
        }
    }*/
    
    func listen() {
            handle = authService.listenToAuthStateChanges { [weak self] firebaseUser in
                guard let self = self else { return }
                
                Task { @MainActor in
                    if let firebaseUser = firebaseUser {
                        self.session = AppUser(uid: firebaseUser.uid, email: firebaseUser.email)
                        print("✅ Utilisateur connecté : \(firebaseUser.email ?? "sans email")")
                    } else {
                        self.session = nil
                        print("👤 Utilisateur déconnecté")
                    }
                }
            }
        }
    /*func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                print("Error creating user: \(error.localizedDescription) \(error)")
            } else {
                DispatchQueue.main.async { //ajouté car closure pas forcément sur thread principal
                    self?.session = AppUser(uid: result?.user.uid ?? "", email: result?.user.email ?? "")
                }
            }
        }
    }*/
    
    func signUp(email: String, password: String) {
        authService.signUp(email: email, password: password) { [weak self] (user, error) in
            DispatchQueue.main.async { //ajouté car closure pas forcément sur thread principal
                if let user = user {
                    self?.session = AppUser(uid: user.uid, email: user.email)
                } else if let error = error {
                    print("error \(error)")
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async { //ajouté car closure pas forcément sur thread principal
                    self?.session = AppUser(uid: result?.user.uid ?? "", email: result?.user.email ?? "")
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.session = nil
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    func unbind() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
}
