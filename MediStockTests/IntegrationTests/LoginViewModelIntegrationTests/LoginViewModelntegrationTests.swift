//
//  LoginViewModelntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//
import XCTest
import Combine
@testable import MediStock

final class LoginViewModelIntegrationTests: XCTestCase {
    
    var sut: LoginViewModel!
    var fakeAuthService: FakeAuthIntegrationService!
    var fakeFirestoreService: FakeFirestoreIntegrationService!
    var fakeSessionVM: FakeSessionViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        fakeAuthService = FakeAuthIntegrationService()
        fakeFirestoreService = FakeFirestoreIntegrationService()
        fakeSessionVM = FakeSessionViewModel()
        
        sut = LoginViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreService,
            sessionVM: fakeSessionVM
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        sut = nil
        fakeAuthService = nil
        fakeFirestoreService = nil
        fakeSessionVM = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Tests SignUp
    
    func test_signUp_withValidCredentials_shouldCreateUserAndUpdateSession() {
        // Given
        let email = "test@example.com"
        let password = "password123"
        let expectation = expectation(description: "SignUp completion")
        
        var sessionUpdated = false
        var errorReceived: AppError?
        
        fakeSessionVM.$session
            .dropFirst()
            .sink { user in
                if user?.email == email {
                    sessionUpdated = true
                }
            }
            .store(in: &cancellables)
        
        sut.$appError
            .sink { error in
                errorReceived = error
            }
            .store(in: &cancellables)
        
        // When
        sut.signUp(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(fakeAuthService.lastSignUpEmail, email, "L'email devrait être passé au service d'auth")
        XCTAssertTrue(sessionUpdated, "La session devrait être mise à jour")
        XCTAssertNil(errorReceived, "Aucune erreur ne devrait être présente")
        XCTAssertEqual(fakeSessionVM.session?.email, email, "L'email de la session devrait correspondre")
        XCTAssertEqual(fakeSessionVM.session?.uid, "fakeUID", "L'UID devrait être celui du fake service")
    }
    
    func test_signUp_shouldCreateUserInFirestore() {
        // Given
        let email = "firestore@example.com"
        let password = "password123"
        let expectation = expectation(description: "SignUp with Firestore")
        
        // When
        sut.signUp(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // ✅ Vérifications Firestore
        XCTAssertTrue(fakeFirestoreService.createUserCalled, "createUser devrait être appelé")
        XCTAssertEqual(fakeFirestoreService.createUserCallCount, 1, "createUser devrait être appelé une fois")
        XCTAssertEqual(fakeFirestoreService.users.count, 1, "Un utilisateur devrait être créé")
        XCTAssertEqual(fakeFirestoreService.users.first?.email, email, "L'email devrait correspondre")
        XCTAssertEqual(fakeFirestoreService.users.first?.uid, "fakeUID", "L'UID devrait correspondre")
    }
    
    func test_signUp_withAuthError_shouldSetAppError() {
        // Given
        let email = "error@example.com"
        let password = "wrong"
        let expectation = expectation(description: "SignUp with error")
        
        let fakeAuthWithError = FakeAuthServiceWithError()
        sut = LoginViewModel(
            authService: fakeAuthWithError,
            firestoreService: fakeFirestoreService,
            sessionVM: fakeSessionVM
        )
        
        var errorReceived: AppError?
        sut.$appError
            .sink { error in
                errorReceived = error
            }
            .store(in: &cancellables)
        
        // When
        sut.signUp(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(errorReceived, "Une erreur devrait être présente")
        XCTAssertFalse(fakeFirestoreService.createUserCalled, "createUser ne devrait pas être appelé en cas d'erreur auth")
    }
    
    func test_signUp_withFirestoreError_shouldSetAppError() {
        // Given
        let email = "firestore-error@example.com"
        let password = "password123"
        let expectation = expectation(description: "SignUp with Firestore error")
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = LoginViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            sessionVM: fakeSessionVM
        )
        
        fakeSessionVM.session = nil
        
        var errorReceived: AppError?
        sut.$appError
            .sink { error in
                errorReceived = error
            }
            .store(in: &cancellables)
        
        // When
        sut.signUp(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(errorReceived, "Une erreur devrait être présente")
        XCTAssertNil(fakeSessionVM.session, "La session ne devrait pas être mise à jour en cas d'erreur Firestore")
    }
    
    // MARK: - Tests SignIn
    
    func test_signIn_withValidCredentials_shouldUpdateSession() {
        // Given
        let email = "signin@example.com"
        let password = "password123"
        let expectation = expectation(description: "SignIn completion")
        
        var sessionUpdated = false
        
        fakeSessionVM.$session
            .dropFirst()
            .sink { user in
                if user?.email == email {
                    sessionUpdated = true
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.signIn(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(fakeAuthService.lastSignInEmail, email, "L'email devrait être passé au service d'auth")
        XCTAssertTrue(sessionUpdated, "La session devrait être mise à jour")
        XCTAssertNil(sut.appError, "Aucune erreur ne devrait être présente")
        XCTAssertEqual(fakeSessionVM.session?.email, email, "L'email de la session devrait correspondre")
    }
    
    func test_signIn_shouldNotCallFirestore() {
        // Given
        let email = "signin@example.com"
        let password = "password123"
        let expectation = expectation(description: "SignIn without Firestore")
        
        // When
        sut.signIn(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertFalse(fakeFirestoreService.createUserCalled, "createUser ne devrait pas être appelé lors du signIn")
        XCTAssertEqual(fakeFirestoreService.users.count, 0, "Aucun utilisateur ne devrait être créé")
    }
    
    func test_signIn_withAuthError_shouldSetAppError() {
        // Given
        let email = "error@example.com"
        let password = "wrong"
        let expectation = expectation(description: "SignIn with error")
        
        let fakeAuthWithError = FakeAuthServiceWithError()
        sut = LoginViewModel(
            authService: fakeAuthWithError,
            firestoreService: fakeFirestoreService,
            sessionVM: fakeSessionVM
        )
        
        var errorReceived: AppError?
        sut.$appError
            .sink { error in
                errorReceived = error
            }
            .store(in: &cancellables)
        
        // When
        sut.signIn(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(errorReceived, "Une erreur devrait être présente")
    }
    
    func test_signIn_shouldClearPreviousError() {
        // Given
        let expectation = expectation(description: "SignIn clears error")
        sut.appError = AppError.fromAuth(NSError(domain: "Test", code: 1))
        
        // When
        sut.signIn(email: "test@example.com", password: "password") {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNil(sut.appError, "L'erreur précédente devrait être effacée")
    }
    
    // MARK: - Tests d'intégration complets
    
    func test_fullSignUpFlow_shouldCompleteSuccessfully() {
        // Given
        let email = "integration@example.com"
        let password = "securePassword123"
        let expectation = expectation(description: "Full signup flow")
        
        var finalSessionUser: AppUser?
        
        fakeSessionVM.$session
            .dropFirst()
            .sink { user in
                finalSessionUser = user
            }
            .store(in: &cancellables)
        
        // When
        sut.signUp(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // Vérifications Auth
        XCTAssertEqual(fakeAuthService.lastSignUpEmail, email)
        
        // Vérifications Firestore
        XCTAssertTrue(fakeFirestoreService.createUserCalled)
        XCTAssertEqual(fakeFirestoreService.users.count, 1)
        XCTAssertEqual(fakeFirestoreService.users.first?.email, email)
        
        // Vérifications Session
        XCTAssertNotNil(finalSessionUser, "La session devrait contenir un utilisateur")
        XCTAssertEqual(finalSessionUser?.email, email)
        XCTAssertEqual(finalSessionUser?.uid, "fakeUID")
        
        // Vérifications Erreur
        XCTAssertNil(sut.appError)
    }
    
    func test_fullSignInFlow_shouldCompleteSuccessfully() {
        // Given
        let email = "signin@example.com"
        let password = "password123"
        let expectation = expectation(description: "Full signin flow")
        
        var finalSessionUser: AppUser?
        
        fakeSessionVM.$session
            .dropFirst()
            .sink { user in
                finalSessionUser = user
            }
            .store(in: &cancellables)
        
        // When
        sut.signIn(email: email, password: password) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertNotNil(finalSessionUser, "La session devrait contenir un utilisateur")
        XCTAssertEqual(finalSessionUser?.email, email)
        XCTAssertEqual(fakeAuthService.lastSignInEmail, email)
        XCTAssertNil(sut.appError)
        XCTAssertFalse(fakeFirestoreService.createUserCalled, "Firestore ne devrait pas être appelé lors du signIn")
    }
    
    // MARK: - Tests de concurrence
    
    func test_multipleSignUpCalls_shouldHandleConcurrently() {
        // Given
        let expectation1 = expectation(description: "SignUp 1")
        let expectation2 = expectation(description: "SignUp 2")
        
        // When
        sut.signUp(email: "user1@example.com", password: "pass1") {
            expectation1.fulfill()
        }
        
        sut.signUp(email: "user2@example.com", password: "pass2") {
            expectation2.fulfill()
        }
        
        // Then
        wait(for: [expectation1, expectation2], timeout: 3.0)
        
        XCTAssertNotNil(fakeSessionVM.session)
        XCTAssertEqual(fakeFirestoreService.createUserCallCount, 2, "createUser devrait être appelé deux fois")
        XCTAssertEqual(fakeFirestoreService.users.count, 2, "Deux utilisateurs devraient être créés")
    }
}
