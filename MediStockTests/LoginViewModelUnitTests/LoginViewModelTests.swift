//
//  LoginViewModelTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
@testable import MediStock

final class LoginViewModelTests: XCTestCase {
    
    var loginVM: LoginViewModel!
    var mockSessionViewModel: MockSessionViewModel!
    var mockAuth: MockAuthService!
    var mockFirestore: MockFiresotreService!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        mockFirestore = MockFiresotreService()
        mockSessionViewModel = MockSessionViewModel(authService: mockAuth, firestoreService: mockFirestore)
        
        loginVM = LoginViewModel(
            authService: mockAuth,
            firestoreService: mockFirestore,
            sessionVM: mockSessionViewModel
        )
    }
    
    override func tearDown() {
        loginVM = nil
        mockSessionViewModel = nil
        mockAuth = nil
        mockFirestore = nil
        super.tearDown()
    }
    
    // MARK: - signUp Success
    func test_signUp_success_updatesSession() {
        // Given
        let mockUser = AppUser(uid: "123", email: "test@test.com")
        mockAuth.mockUser = mockUser
        let exp = expectation(description: "signUp completed")
        
        // When
        loginVM.signUp(email: "test@test.com", password: "123456") {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertEqual(mockSessionViewModel.session?.uid, "123")
        XCTAssertNil(loginVM.appError)
        XCTAssertTrue(mockAuth.signUpCalled)
    }
    
    // MARK: - signUp Auth Error
    func test_signUp_authError_setsAppError() {
        // Given
        mockAuth.mockError = NSError(domain: "Auth", code: 1)
        let exp = expectation(description: "signUp completed")
        
        // When
        loginVM.signUp(email: "test@test.com", password: "123456") {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertNotNil(loginVM.appError)
        XCTAssertTrue(mockAuth.signUpCalled)
        XCTAssertNil(mockSessionViewModel.session)
    }
    
    // MARK: - signUp Firestore Error
    func test_signUp_firestoreError_setsAppError() {
        // Given
        let mockUser = AppUser(uid: "123", email: "test@test.com")
        mockAuth.mockUser = mockUser
        mockFirestore.shouldThrowOnCreateUser = true // à ajouter comme flag dans le mock
        let exp = expectation(description: "signUp completed")
        
        // When
        loginVM.signUp(email: "test@test.com", password: "123456") {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertNotNil(loginVM.appError)
        XCTAssertNil(mockSessionViewModel.session)
    }
    
    // MARK: - signIn Success
    func test_signIn_success_updatesSession() {
        // Given
        let mockUser = AppUser(uid: "123", email: "test@test.com")
        mockAuth.mockUser = mockUser
        let exp = expectation(description: "signIn completed")
        
        // When
        loginVM.signIn(email: "test@test.com", password: "123456") {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertEqual(mockSessionViewModel.session?.uid, "123")
        XCTAssertNil(loginVM.appError)
        XCTAssertTrue(mockAuth.signInCalled)
    }
    
    // MARK: - signIn Error
    func test_signIn_error_setsAppError() {
        // Given
        mockAuth.mockError = NSError(domain: "Auth", code: 1)
        let exp = expectation(description: "signIn completed")
        
        // When
        loginVM.signIn(email: "test@test.com", password: "123456") {
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1)
        
        // Then
        XCTAssertNotNil(loginVM.appError)
        XCTAssertNil(mockSessionViewModel.session)
        XCTAssertTrue(mockAuth.signInCalled)
    }
}
