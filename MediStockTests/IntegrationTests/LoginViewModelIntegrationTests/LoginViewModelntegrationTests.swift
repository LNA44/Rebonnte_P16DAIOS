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
        
        XCTAssertEqual(fakeAuthService.lastSignUpEmail, email)
        XCTAssertTrue(sessionUpdated)
        XCTAssertNil(errorReceived)
        XCTAssertEqual(fakeSessionVM.session?.email, email)
        XCTAssertEqual(fakeSessionVM.session?.uid, "fakeUID")
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
        XCTAssertTrue(fakeFirestoreService.createUserCalled)
        XCTAssertEqual(fakeFirestoreService.createUserCallCount, 1)
        XCTAssertEqual(fakeFirestoreService.users.count, 1)
        XCTAssertEqual(fakeFirestoreService.users.first?.email, email)
        XCTAssertEqual(fakeFirestoreService.users.first?.uid, "fakeUID")
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
        
        XCTAssertNotNil(errorReceived)
        XCTAssertFalse(fakeFirestoreService.createUserCalled)
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
        
        XCTAssertNotNil(errorReceived)
        XCTAssertNil(fakeSessionVM.session)
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
        
        XCTAssertEqual(fakeAuthService.lastSignInEmail, email)
        XCTAssertTrue(sessionUpdated)
        XCTAssertNil(sut.appError)
        XCTAssertEqual(fakeSessionVM.session?.email, email)
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
        
        XCTAssertFalse(fakeFirestoreService.createUserCalled)
        XCTAssertEqual(fakeFirestoreService.users.count, 0)
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
        
        XCTAssertNotNil(errorReceived)
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
        
        XCTAssertNil(sut.appError)
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
        XCTAssertNotNil(finalSessionUser)
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
        
        XCTAssertNotNil(finalSessionUser)
        XCTAssertEqual(finalSessionUser?.email, email)
        XCTAssertEqual(fakeAuthService.lastSignInEmail, email)
        XCTAssertNil(sut.appError)
        XCTAssertFalse(fakeFirestoreService.createUserCalled)
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
        XCTAssertEqual(fakeFirestoreService.createUserCallCount, 2)
        XCTAssertEqual(fakeFirestoreService.users.count, 2)
    }
}
