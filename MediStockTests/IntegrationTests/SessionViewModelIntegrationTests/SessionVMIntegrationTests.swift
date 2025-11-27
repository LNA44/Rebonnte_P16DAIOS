//
//  SessionVMIntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
@testable import MediStock

@MainActor
final class SessionViewModelIntegrationTests: XCTestCase {
    
    var sut: SessionViewModel!
    var fakeAuthService: FakeAuthIntegrationService!
    var fakeFirestoreService: FakeFirestoreIntegrationService!
    
    override func setUp() {
        super.setUp()
        fakeAuthService = FakeAuthIntegrationService()
        fakeFirestoreService = FakeFirestoreIntegrationService()
        sut = SessionViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreService
        )
    }
    
    override func tearDown() {
        sut.unbind()
        sut = nil
        fakeAuthService = nil
        fakeFirestoreService = nil
        super.tearDown()
    }
    
    // MARK: - Listen Tests
    
    func test_listen_whenUserConnected_shouldUpdateSession() async {
        // Given
        let expectedUser = (uid: "user123", email: "test@example.com")
        
        // When
        sut.listen()
        
        // Simuler une connexion
        fakeAuthService.simulateAuthStateChange(user: expectedUser)
        
        // Attendre la mise à jour asynchrone
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
        
        // Then
        XCTAssertNotNil(sut.session)
        XCTAssertEqual(sut.session?.uid, expectedUser.uid)
        XCTAssertEqual(sut.session?.email, expectedUser.email)
        XCTAssertNotNil(sut.handle)
    }
    
    func test_listen_whenUserDisconnected_shouldClearSession() async {
        // Given - Connecter un utilisateur
        sut.listen()
        fakeAuthService.simulateAuthStateChange(user: ("user123", "test@example.com"))
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        XCTAssertNotNil(sut.session, "Precondition: session should be set")
        
        // When - Simuler une déconnexion
        fakeAuthService.simulateAuthStateChange(user: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNil(sut.session)
        XCTAssertNil(sut.handle, "Handle should be removed on logout")
    }
    
    func test_listen_multipleStateChanges_shouldUpdateSessionCorrectly() async {
        // Given
        sut.listen()

        // When - Connexion
        let user1 = (uid: "user1", email: "user1@test.com")
        fakeAuthService.simulateAuthStateChange(user: user1)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.session?.uid, user1.uid)

        // When - Déconnexion
        fakeAuthService.simulateAuthStateChange(user: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertNil(sut.session)
        XCTAssertNil(sut.handle, "Listen should be deleted after logout")

        // When - Relancer l'écoute pour une nouvelle session
        sut.listen()
        let user2 = (uid: "user2", email: "user2@test.com")
        fakeAuthService.simulateAuthStateChange(user: user2)
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(sut.session?.uid, user2.uid)
        XCTAssertEqual(sut.session?.email, user2.email)
    }

    
    // MARK: - UpdateSession Tests
    
    func test_updateSession_shouldSetSessionDirectly() {
        // Given
        let user = AppUser(uid: "direct123", email: "direct@test.com")
        
        // When
        sut.updateSession(user: user)
        
        // Then
        XCTAssertEqual(sut.session?.uid, user.uid)
        XCTAssertEqual(sut.session?.email, user.email)
    }
    
    func test_updateSession_withNil_shouldClearSession() {
        // Given
        sut.updateSession(user: AppUser(uid: "test", email: "test@test.com"))
        XCTAssertNotNil(sut.session, "Precondition: session should be set")
        
        // When
        sut.updateSession(user: nil)
        
        // Then
        XCTAssertNil(sut.session)
    }
    
    // MARK: - Unbind Tests
    
    func test_unbind_shouldRemoveListener() async {
        // Given
        sut.listen()
        XCTAssertNotNil(sut.handle, "Precondition: handle should be set")
        
        // When
        sut.unbind()
        
        // Then
        XCTAssertNil(sut.handle)
        XCTAssertTrue(fakeAuthService.listenerRemoved, "Listener should be removed from auth service")
    }
    
    func test_unbind_whenNoListener_shouldNotCrash() {
        // Given - Pas de listener actif
        XCTAssertNil(sut.handle)
        
        // When/Then - Ne devrait pas crasher
        sut.unbind()
        
        XCTAssertNil(sut.handle)
    }
    
    func test_unbind_afterMultipleCalls_shouldBeIdempotent() async {
        // Given
        sut.listen()
        
        // When
        sut.unbind()
        sut.unbind()
        sut.unbind()
        
        // Then
        XCTAssertNil(sut.handle)
    }
    
    // MARK: - Integration Flow Tests
    
    func test_completeFlow_listenLoginLogoutUnbind() async {
        // Given - Démarrer l'écoute
        sut.listen()
        XCTAssertNil(sut.session)
        
        // When - Connexion
        let user = (uid: "flow123", email: "flow@test.com")
        fakeAuthService.simulateAuthStateChange(user: user)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then - Session créée
        XCTAssertNotNil(sut.session)
        XCTAssertEqual(sut.session?.uid, user.uid)
        
        // When - Déconnexion
        fakeAuthService.simulateAuthStateChange(user: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then
        XCTAssertNil(sut.session)
        
        // When 
        sut.unbind()
        
        // Then - Handle supprimé
        XCTAssertNil(sut.handle)
    }
}

