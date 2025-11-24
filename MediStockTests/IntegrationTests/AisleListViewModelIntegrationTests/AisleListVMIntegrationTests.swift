//
//  AisleListVMIntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
import Combine
@testable import MediStock

final class AisleListViewModelIntegrationTests: XCTestCase {

    var firestore: FakeFirestoreIntegrationService!
    var auth: FakeAuthIntegrationService!
    var session: FakeSessionViewModel!
    var viewModel: AisleListViewModel!
    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        firestore = FakeFirestoreIntegrationService()
        auth = FakeAuthIntegrationService()
        session = FakeSessionViewModel()

        viewModel = AisleListViewModel(
            sessionVM: session,
            authService: auth,
            firestoreService: firestore
        )
    }

    override func tearDown() {
        firestore = nil
        auth = nil
        session = nil
        viewModel = nil
        cancellables.removeAll()
    }

    // MARK: - fetchAisles
    func test_fetchAisles_shouldUpdatePublishedAisles() {
        // Given
        firestore.aisles = ["A", "B", "C"]
        let expectation = expectation(description: "Aisles updated")

        viewModel.$aisles
            .dropFirst() // ignore initial empty value
            .sink { aisles in
                XCTAssertEqual(aisles, ["A", "B", "C"])
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        viewModel.fetchAisles()

        // Then
        wait(for: [expectation], timeout: 1)
        XCTAssertNil(viewModel.appError)
        XCTAssertNotNil(viewModel.aislesListener)
    }

    func test_fetchAisles_shouldReplaceOldListener() {
        // Given
        let old = FakeListenerRegistration()
        viewModel.aislesListener = old

        // When
        viewModel.fetchAisles()

        // Then
        XCTAssertNotNil(viewModel.aislesListener)
        XCTAssertFalse(viewModel.aislesListener === old)
    }

    // MARK: - signOut
    func test_signOut_shouldRemoveListener_andClearSession() {
        // Given
        let listener = FakeListenerRegistration()
        viewModel.aislesListener = listener

        // When
        viewModel.signOut()

        // Then
        XCTAssertNil(viewModel.aislesListener)
        XCTAssertTrue(auth.didSignOut)
        XCTAssertNil(session.session)
    }

    func test_signOut_shouldSetAppError_onFailure() {
        // Given
        auth.shouldThrowOnSignOut = true

        // When
        viewModel.signOut()

        // Then
        XCTAssertNotNil(viewModel.appError)
    }

    // MARK: - deinit
    func test_viewModel_deinit_shouldRemoveListener() {
        // Given
        var vm: AisleListViewModel? = AisleListViewModel(
            sessionVM: session,
            authService: auth,
            firestoreService: firestore
        )

        let listener = FakeListenerRegistration()
        vm?.aislesListener = listener

        weak var weakVM = vm

        // When
        vm = nil

        // Then
        XCTAssertNil(weakVM)
    }
}
