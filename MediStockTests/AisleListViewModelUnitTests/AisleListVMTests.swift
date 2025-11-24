//
//  MediStockTests.swift
//  MediStockTests
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import XCTest
@testable import MediStock

final class AisleListTests: XCTestCase {

    var viewModel: AisleListViewModel!
    var mockSessionViewModel: MockSessionViewModel!
    var mockAuth: MockAuthService!
    var mockFirestore: MockFiresotreService!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        mockFirestore = MockFiresotreService()
        mockSessionViewModel = MockSessionViewModel(
                authService: mockAuth,
                firestoreService: mockFirestore
            )
        viewModel = AisleListViewModel(
            sessionVM: mockSessionViewModel,
            authService: mockAuth,
            firestoreService: mockFirestore // <-- important
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockSessionViewModel = nil
        mockAuth = nil
        mockFirestore = nil
        super.tearDown()
    }

    func test_fetchAisles_success_updatesAisles() {

        // Given
        let expectedAisles = ["A", "B", "C"]
        mockFirestore.fetchAislesResult = (expectedAisles, nil)

        // When
        viewModel.fetchAisles()

        // Then
        XCTAssertEqual(viewModel.aisles, expectedAisles)
        XCTAssertNil(viewModel.appError)
    }
    
    func test_fetchAisles_error_setsAppError() {

        // Given
        let error = NSError(domain: "Firestore", code: 1)
        mockFirestore.fetchAislesResult = ([], error)

        // When
        viewModel.fetchAisles()

        // Then
        XCTAssertNotNil(viewModel.appError)
        XCTAssertTrue(viewModel.aisles.isEmpty)
    }
    
    func test_fetchAisles_removesPreviousListener() {

        // Given
        let oldListener = MockListenerRegistration()
        viewModel.aislesListener = oldListener

        // When
        viewModel.fetchAisles()

        // Then
        XCTAssertEqual(oldListener.removeCallCount, 1)
    }
    
    func test_signOut_success_clearsSession() {

        // Given
        mockAuth.shouldThrowOnSignOut = false
        mockSessionViewModel.session = AppUser(uid: "123", email: "toto@test.com")

        // When
        viewModel.signOut()

        // Then
        XCTAssertNil(mockSessionViewModel.session)
        XCTAssertNil(viewModel.appError)
    }
    
    func test_signOut_error_setsAppError() {

        // Given
        mockAuth.shouldThrowOnSignOut = true

        // When
        viewModel.signOut()

        // Then
        XCTAssertNotNil(viewModel.appError)
    }
    
    func test_userDidSignOut_stopsListeners() {

        // Given
        let listener = MockListenerRegistration()
        viewModel.aislesListener = listener

        // When
        NotificationCenter.default.post(name: .userDidSignOut, object: nil)

        // Then
        XCTAssertEqual(listener.removeCallCount, 1)
        XCTAssertNil(viewModel.aislesListener)
    }
    
    func test_deinit_removesNotificationObservers() {

        // Given
        weak var weakVM: AisleListViewModel?
        autoreleasepool {
            let vm = AisleListViewModel(
                sessionVM: mockSessionViewModel,
                authService: mockAuth,
                firestoreService: mockFirestore
            )
            weakVM = vm
        }

        // When / Then
        XCTAssertNil(weakVM)
    }
}
