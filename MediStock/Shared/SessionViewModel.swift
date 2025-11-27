import Foundation
import Firebase

class SessionViewModel: ObservableObject {
    static let shared = SessionViewModel()

    @Published var session: AppUser?
    var handle: AuthStateDidChangeListenerHandle?
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    
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
                } else {
                    self?.session = nil
                    self?.unbind()
                }
            }
        }
    }
    
    func updateSession(user: AppUser?) {
        self.session = user
    }
    
    func unbind() {
        guard handle != nil else { return }
        authService.removeListener(handle: handle)
        handle = nil
    }
}
