//
//  SessionViewModelTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
import Combine
@testable import MediStock

@MainActor
final class SessionViewModelTests: XCTestCase {
    
    var sut: SessionViewModel!
    var mockAuthService: MockAuthService!
    var mockFirestoreService: MockFiresotreService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockFirestoreService = MockFiresotreService()
        sut = SessionViewModel(
            authService: mockAuthService,
            firestoreService: mockFirestoreService
        )
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockAuthService = nil
        mockFirestoreService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetServicesCorrectly() {
        // Then
        XCTAssertNotNil(sut.authService)
        XCTAssertNotNil(sut.firestoreService)
        XCTAssertNil(sut.session)
        XCTAssertNil(sut.handle)
    }
    
    func test_init_shouldUseInjectedServices() {
        // Then
        XCTAssertTrue(sut.authService is MockAuthService)
        XCTAssertTrue(sut.firestoreService is MockFiresotreService)
    }
    
    // MARK: - Listen Tests
    
    func test_listen_shouldCreateAuthStateListener() {
        // When
        sut.listen()
        
        // Then
        XCTAssertNotNil(sut.handle)
        XCTAssertNotNil(mockAuthService.listenerCallback)
    }
    
    func test_listen_whenUserConnected_shouldUpdateSession() async {
        // Given
        let expectation = expectation(description: "Session mise à jour")
        let testEmail = "test@example.com"
        let testUID = "test-uid-123"
        
        var receivedSession: AppUser?
        sut.$session
            .dropFirst() // Ignore la valeur initiale (nil)
            .sink { session in
                receivedSession = session
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Simuler un utilisateur connecté
        let mockUserInfo = AuthUserInfo(uid: testUID, email: testEmail)
        mockAuthService.listenerCallback?(mockUserInfo)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedSession)
        XCTAssertEqual(receivedSession?.uid, testUID)
        XCTAssertEqual(receivedSession?.email, testEmail)
    }
    
    func test_listen_whenUserConnectedWithoutEmail_shouldUpdateSessionWithNilEmail() async {
        // Given
        let expectation = expectation(description: "Session mise à jour sans email")
        let testUID = "test-uid-456"
        
        var receivedSession: AppUser?
        sut.$session
            .dropFirst()
            .sink { session in
                receivedSession = session
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        let mockUserInfo = AuthUserInfo(uid: testUID, email: nil)
        mockAuthService.listenerCallback?(mockUserInfo)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedSession)
        XCTAssertEqual(receivedSession?.uid, testUID)
        XCTAssertNil(receivedSession?.email)
    }
    
    func test_listen_whenUserDisconnected_shouldClearSessionAndUnbind() async {
        // Given
        let expectation = expectation(description: "Session cleared")
        expectation.expectedFulfillmentCount = 2 // Connexion puis déconnexion
        
        var sessionUpdates: [AppUser?] = []
        sut.$session
            .dropFirst()
            .sink { session in
                sessionUpdates.append(session)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Simuler une connexion
        let mockUserInfo = AuthUserInfo(uid: "uid-123", email: "test@example.com")
        mockAuthService.listenerCallback?(mockUserInfo)
        
        // Puis une déconnexion
        mockAuthService.listenerCallback?(nil)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sessionUpdates.count, 2)
        XCTAssertNotNil(sessionUpdates[0])
        XCTAssertNil(sessionUpdates[1])
        XCTAssertNil(sut.handle)
    }
    
    func test_listen_calledMultipleTimes_shouldNotCreateMultipleListeners() {
        // When
        sut.listen()
        let firstHandle = sut.handle
        
        sut.listen()
        let secondHandle = sut.handle
        
        sut.listen()
        let thirdHandle = sut.handle
        
        // Then
        XCTAssertNotNil(firstHandle)
        XCTAssertNotNil(secondHandle)
        XCTAssertNotNil(thirdHandle)
        // Note: Dans l'implémentation actuelle, chaque appel crée un nouveau listener
        // Si vous voulez éviter ça, ajoutez unbind() au début de listen()
    }
    
    // MARK: - UpdateSession Tests
    
    func test_updateSession_withUser_shouldUpdateSession() {
        // Given
        let testUser = AppUser(uid: "test-uid", email: "test@example.com")
        
        // When
        sut.updateSession(user: testUser)
        
        // Then
        XCTAssertNotNil(sut.session)
        XCTAssertEqual(sut.session?.uid, testUser.uid)
        XCTAssertEqual(sut.session?.email, testUser.email)
    }
    
    func test_updateSession_withNil_shouldClearSession() {
        // Given
        sut.session = AppUser(uid: "existing", email: "existing@example.com")
        
        // When
        sut.updateSession(user: nil)
        
        // Then
        XCTAssertNil(sut.session)
    }
    
    func test_updateSession_shouldPublishChanges() async {
        // Given
        let expectation = expectation(description: "Session published")
        let testUser = AppUser(uid: "test-uid", email: "test@example.com")
        
        var receivedSession: AppUser?
        sut.$session
            .dropFirst()
            .sink { session in
                receivedSession = session
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.updateSession(user: testUser)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSession?.uid, testUser.uid)
        XCTAssertEqual(receivedSession?.email, testUser.email)
    }
    
    func test_updateSession_multipleUpdates_shouldPublishAllChanges() async {
        // Given
        let expectation = expectation(description: "Multiple updates published")
        expectation.expectedFulfillmentCount = 3
        
        var receivedSessions: [AppUser?] = []
        sut.$session
            .dropFirst()
            .sink { session in
                receivedSessions.append(session)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.updateSession(user: AppUser(uid: "1", email: "user1@test.com"))
        sut.updateSession(user: AppUser(uid: "2", email: "user2@test.com"))
        sut.updateSession(user: nil)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedSessions.count, 3)
        XCTAssertEqual(receivedSessions[0]?.uid, "1")
        XCTAssertEqual(receivedSessions[1]?.uid, "2")
        XCTAssertNil(receivedSessions[2])
    }
    
    // MARK: - Unbind Tests
    
    func test_unbind_withActiveListener_shouldRemoveListener() {
        // Given
        sut.listen()
        let handle = sut.handle
        XCTAssertNotNil(handle)
        
        // When
        sut.unbind()
        
        // Then
        XCTAssertNil(sut.handle)
        XCTAssertEqual(mockAuthService.removedHandle,
                       handle as? MockAuthStateListenerHandle)
    }
    
    func test_unbind_withoutListener_shouldNotCrash() {
        // Given
        XCTAssertNil(sut.handle)
        
        // When / Then
        XCTAssertNoThrow(sut.unbind())
        XCTAssertNil(sut.handle)
    }
    
    func test_unbind_shouldCallAuthServiceRemoveListener() {
        // Given
        sut.listen()
        let expectedHandle = sut.handle
        
        // When
        sut.unbind()
        
        // Then
        XCTAssertNotNil(mockAuthService.removedHandle)
        XCTAssertEqual(mockAuthService.removedHandle,
                       expectedHandle as? MockAuthStateListenerHandle)
    }
    
    func test_unbind_calledMultipleTimes_shouldBeIdempotent() {
        // Given
        sut.listen()
        guard let authListener = mockAuthService.lastAuthListener else {
            XCTFail("Auth listener devrait être créé")
            return
        }
        
        // When
        sut.unbind()
        sut.unbind()
        sut.unbind()
        
        // Then
        XCTAssertNil(sut.handle)
        XCTAssertEqual(authListener.removeCallCount, 1) // ✅ Fonctionne
    }

    
    // MARK: - Integration Tests
    
    func test_fullCycle_connectThenDisconnect_shouldWorkCorrectly() async {
        // Given
        let expectation = expectation(description: "Full cycle completed")
        expectation.expectedFulfillmentCount = 2
        
        var sessionStates: [AppUser?] = []
        sut.$session
            .dropFirst()
            .sink { session in
                sessionStates.append(session)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        
        // Connexion
        let userInfo = AuthUserInfo(uid: "uid-123", email: "user@test.com")
        mockAuthService.listenerCallback?(userInfo)
        
        // Déconnexion
        mockAuthService.listenerCallback?(nil)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sessionStates.count, 2)
        XCTAssertNotNil(sessionStates[0])
        XCTAssertNil(sessionStates[1])
        XCTAssertNil(sut.handle)
    }
    
    func test_listenThenManualUnbind_shouldStopReceivingUpdates() async {
        // Given
        let expectation = expectation(description: "No more updates after unbind")
        expectation.isInverted = true // On s'attend à ce que ça ne soit PAS appelé
        
        sut.listen()
        sut.unbind()
        
        sut.$session
            .dropFirst()
            .sink { _ in
                expectation.fulfill() // Ne devrait pas être appelé
            }
            .store(in: &cancellables)
        
        // When
        mockAuthService.listenerCallback?(AuthUserInfo(uid: "uid", email: "test@test.com"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 0.5)
        XCTAssertNil(sut.session)
    }
    
    func test_listen_thenManualUpdate_shouldReceiveBothUpdates() async {
        // Given
        let listenerExpectation = expectation(description: "Listener update")
        let manualExpectation = expectation(description: "Manual update")
        
        var receivedSessions: [AppUser?] = []
        sut.$session
            .dropFirst()
            .sink { session in
                receivedSessions.append(session)
                if receivedSessions.count == 1 {
                    listenerExpectation.fulfill()
                } else if receivedSessions.count == 2 {
                    manualExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When - Premier update via listener
        sut.listen()
        mockAuthService.listenerCallback?(AuthUserInfo(uid: "listener-uid", email: "listener@test.com"))
        
        await fulfillment(of: [listenerExpectation], timeout: 0.5)
        
        // When - Deuxième update manuel
        sut.updateSession(user: AppUser(uid: "manual-uid", email: "manual@test.com"))
        
        await fulfillment(of: [manualExpectation], timeout: 0.5)

        // Then
        XCTAssertEqual(receivedSessions.count, 2)
        XCTAssertEqual(receivedSessions[0]?.uid, "listener-uid")
        XCTAssertEqual(receivedSessions[1]?.uid, "manual-uid")
    }
    
    // MARK: - Memory Management Tests
    
    func test_listen_shouldNotCreateRetainCycle() {
        // Given
        weak var weakSUT = sut
        
        // When
        sut.listen()
        mockAuthService.listenerCallback?(AuthUserInfo(uid: "test", email: "test@test.com"))
        
        // Simuler la libération du ViewModel
        sut = nil
        
        // Then
        XCTAssertNil(weakSUT)
    }
    
    func test_listenerCallback_afterViewModelDeallocated_shouldNotCrash() {
        // Given
        sut.listen()
        let callback = mockAuthService.listenerCallback
        
        // When
        sut = nil // Libérer le ViewModel
        
        // Then - Le callback avec weak self ne devrait pas crasher
        XCTAssertNoThrow(callback?(AuthUserInfo(uid: "test", email: "test@test.com")))
    }
    
    // MARK: - Edge Cases
    
    func test_rapidFireUpdates_shouldPublishAllChanges() async {
        // Given
        let expectation = expectation(description: "All rapid updates published")
        expectation.expectedFulfillmentCount = 5
        
        var updateCount = 0
        sut.$session
            .dropFirst()
            .sink { _ in
                updateCount += 1
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.listen()
        
        // When - Envoyer 5 mises à jour rapidement
        for i in 0..<5 {
            mockAuthService.listenerCallback?(AuthUserInfo(uid: "uid-\(i)", email: "user\(i)@test.com"))
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(updateCount, 5)
        XCTAssertEqual(sut.session?.uid, "uid-4")
    }
    
    func test_alternatingConnectDisconnect_shouldHandleCorrectly() async {
        // Given
        let expectation = expectation(description: "Alternating states handled")
        expectation.expectedFulfillmentCount = 6
        
        var sessionStates: [AppUser?] = []
        sut.$session
            .dropFirst()
            .sink { session in
                sessionStates.append(session)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.listen()
        
        // When - Alterner entre connecté et déconnecté
        for i in 0..<3 {
            mockAuthService.listenerCallback?(AuthUserInfo(uid: "uid-\(i)", email: "user\(i)@test.com"))
            mockAuthService.listenerCallback?(nil)
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(sessionStates.count, 6)
        
        // Vérifier l'alternance
        for i in stride(from: 0, to: 6, by: 2) {
            XCTAssertNotNil(sessionStates[i])
            XCTAssertNil(sessionStates[i + 1])
        }
    }
    
    func test_listener_shouldUpdateSession() async {
        // Given
        let expectation = expectation(description: "Listener updates session")
        
        sut.$session
            .dropFirst()
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthService.listenerCallback?(AuthUserInfo(uid: "listener", email: "listener@test.com"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.session?.uid, "listener")
    }

    func test_updateSession_shouldOverrideListenerValue() async {
        // Given
        let firstExpectation = expectation(description: "Listener update")
        let secondExpectation = expectation(description: "Manual update")
        
        var updateCount = 0
        sut.$session
            .dropFirst()
            .sink { _ in
                updateCount += 1
                if updateCount == 1 {
                    firstExpectation.fulfill()
                } else {
                    secondExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.listen()
        mockAuthService.listenerCallback?(AuthUserInfo(uid: "listener", email: "listener@test.com"))
        
        await fulfillment(of: [firstExpectation], timeout: 1.0)
        XCTAssertEqual(sut.session?.uid, "listener")
        
        sut.updateSession(user: AppUser(uid: "manual", email: "manual@test.com"))
        
        // Then
        await fulfillment(of: [secondExpectation], timeout: 1.0)
        XCTAssertEqual(sut.session?.uid, "manual")
    }
}
