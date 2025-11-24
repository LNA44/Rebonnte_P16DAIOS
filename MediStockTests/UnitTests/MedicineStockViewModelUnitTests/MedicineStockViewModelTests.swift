//
//  MedicineStockViewModelTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
import Combine
@testable import MediStock

import XCTest
import Combine
@testable import MediStock

@MainActor
final class MedicineStockViewModelTests: XCTestCase {
    
    var sut: MedicineStockViewModel!
    var mockFirestoreService: MockFiresotreService!
    var mockDataStore: DataStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockFirestoreService = MockFiresotreService()
        mockDataStore = DataStore()
        sut = MedicineStockViewModel(
            firestoreService: mockFirestoreService,
            dataStore: mockDataStore
        )
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockDataStore = nil
        mockFirestoreService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests (2 tests)
    
    func test_init_shouldSetDefaultValues() {
        // Then
        XCTAssertEqual(sut.filterText, "")
        XCTAssertNil(sut.lastMedicinesDocument)
        XCTAssertEqual(sut.sortOption, .none)
        XCTAssertNil(sut.appError)
    }
    
    func test_init_shouldInjectDependenciesCorrectly() {
        // Then
        XCTAssertTrue(sut.firestoreService is MockFiresotreService) // ✅ CORRIGÉ
        XCTAssertNotNil(sut.dataStore)
        XCTAssertTrue(sut.dataStore === mockDataStore)
        XCTAssertEqual(mockDataStore.medicines.count, 0) // ✅ AJOUTÉ
        XCTAssertEqual(mockDataStore.history.count, 0) // ✅ AJOUTÉ
    }
    
    // MARK: - fetchNextMedicinesBatch Tests (12 tests)
    
    func test_fetchNextMedicinesBatch_withSuccess_shouldAddMedicinesToDataStore() {
        // Given
        let medicines = [
            Medicine(id: "1", name: "Paracétamol", stock: 100, aisle: "A"),
            Medicine(id: "2", name: "Ibuprofène", stock: 50, aisle: "B")
        ]
        mockFirestoreService.fetchMedicinesBatchResult = (medicines, nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockDataStore.medicines.count, 2)
        XCTAssertEqual(mockDataStore.medicines[0].name, "Paracétamol")
        XCTAssertEqual(mockDataStore.medicines[1].name, "Ibuprofène")
    }
    
    func test_fetchNextMedicinesBatch_withSuccess_shouldClearAppError() {
        // Given
        sut.appError = .unknown
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertNil(sut.appError)
    }
    
    func test_fetchNextMedicinesBatch_withError_shouldSetAppError() {
        // Given
        let error = NSError(domain: "Test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, error)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertNotNil(sut.appError)
        XCTAssertEqual(mockDataStore.medicines.count, 0)
    }
    
    func test_fetchNextMedicinesBatch_withError_shouldNotAddMedicines() {
        // Given
        let error = NSError(domain: "Test", code: 500)
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, error)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockDataStore.medicines.count, 0)
    }
    
    func test_fetchNextMedicinesBatch_shouldUpdateLastDocument() {
        // Given
        let lastDoc = MockDocumentSnapshotMedicineStockVM(id: "doc123")
        mockFirestoreService.fetchMedicinesBatchResult = ([], lastDoc, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(sut.lastMedicinesDocument?.id, "doc123")
    }
    
    func test_fetchNextMedicinesBatch_withNilLastDocument_shouldSetToNil() {
        // Given
        sut.lastMedicinesDocument = MockDocumentSnapshotMedicineStockVM(id: "old")
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertNil(sut.lastMedicinesDocument)
    }
    
    func test_fetchNextMedicinesBatch_shouldPassCorrectCollection() {
        // Given
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesCollection, "medicines")
    }
    
    func test_fetchNextMedicinesBatch_shouldPassSortOption() {
        // Given
        sut.sortOption = .name
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesSortOption, .name)
    }
    
    func test_fetchNextMedicinesBatch_withFilterText_shouldPassToService() {
        // Given
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch(filterText: "Para")
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesFilterText, "Para")
    }
    
    func test_fetchNextMedicinesBatch_withSortOption_shouldPassToService() {
        // Given
        sut.sortOption = .stock // ✅ CORRIGÉ
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesSortOption, .stock)
    }

    func test_changeSortOption_affectsNextFetch() {
        // Given
        sut.sortOption = .stock // ✅ CORRIGÉ
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesSortOption, .stock)
        
        // When - Change sort
        sut.sortOption = .name // ✅ CORRIGÉ
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesSortOption, .name)
    }
    
    func test_fetchNextMedicinesBatch_withCustomPageSize_shouldPassToService() {
        // Given
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch(pageSize: 50)
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesPageSize, 50)
    }
    
    func test_sortOption_defaultValue_shouldBeNone() {
        // Then
        XCTAssertEqual(sut.sortOption, .none)
    }
    
    func test_sortOption_canBeChanged() {
        // When
        sut.sortOption = .name
        
        // Then
        XCTAssertEqual(sut.sortOption, .name)
        
        // When
        sut.sortOption = .stock
        
        // Then
        XCTAssertEqual(sut.sortOption, .stock)
    }
    
    func test_fetchNextMedicinesBatch_withDefaultPageSize_shouldUse20() {
        // Given
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesPageSize, 20)
    }
    
    func test_fetchNextMedicinesBatch_withLastDocument_shouldPassToService() {
        // Given
        let lastDoc = MockDocumentSnapshotMedicineStockVM(id: "doc456")
        sut.lastMedicinesDocument = lastDoc
        mockFirestoreService.fetchMedicinesBatchResult = ([], nil, nil)
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastFetchMedicinesLastDocument?.id, "doc456")
    }
    
    // MARK: - deleteMedicines Tests (8 tests)
    
    func test_deleteMedicines_withSuccess_shouldReturnDeletedIds() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A"),
            Medicine(id: "2", name: "Med2", stock: 20, aisle: "B")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertEqual(deletedIds, ["1"])
    }
    
    func test_deleteMedicines_withSuccess_shouldRemoveFromDataStore() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A"),
            Medicine(id: "2", name: "Med2", stock: 20, aisle: "B")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertEqual(mockDataStore.medicines.count, 1)
        XCTAssertEqual(mockDataStore.medicines[0].id, "2")
    }
    
    func test_deleteMedicines_withSuccess_shouldClearAppError() async {
        // Given
        sut.appError = AppError.noPermission
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertNil(sut.appError)
    }
    
    func test_deleteMedicines_withError_shouldSetAppError() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A")
        ])
        let error = NSError(domain: "Test", code: 500)
        mockFirestoreService.deleteMedicinesResult = ([], error)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertNotNil(sut.appError)
    }
    
    func test_deleteMedicines_withError_shouldReturnEmptyArray() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A")
        ])
        let error = NSError(domain: "Test", code: 500)
        mockFirestoreService.deleteMedicinesResult = ([], error)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertTrue(deletedIds.isEmpty)
    }
    
    func test_deleteMedicines_shouldRemoveLocallyBeforeFirestore() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A"),
            Medicine(id: "2", name: "Med2", stock: 20, aisle: "B")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then - Already removed locally even before Firestore call
        XCTAssertEqual(mockDataStore.medicines.count, 1)
    }
    
    func test_deleteMedicines_shouldPassCorrectCollection() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastDeleteMedicinesCollection, "medicines")
    }
    
    func test_deleteMedicines_shouldPassCorrectIds() async {
        // Given
        mockDataStore.addMedicinesToLocal([
            Medicine(id: "1", name: "Med1", stock: 10, aisle: "A"),
            Medicine(id: "2", name: "Med2", stock: 20, aisle: "B"),
            Medicine(id: "3", name: "Med3", stock: 30, aisle: "C")
        ])
        mockFirestoreService.deleteMedicinesResult = (["1", "3"], nil)
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet([0, 2]))
        
        // Then
        XCTAssertEqual(mockFirestoreService.lastDeleteMedicinesIds, ["1", "3"])
    }
    
    func test_deleteMedicines_withHistoryError_shouldRestoreHistory() async {
        // Given
        let medicine = Medicine(id: "1", name: "Med1", stock: 10, aisle: "A")
        mockDataStore.addMedicinesToLocal([medicine])
        mockDataStore.addHistoryEntries([
            HistoryEntry(id: "h1", medicineId: "1", user: "User1", action: "Ajout", details: "10 unités", timestamp: Date())
        ])
        mockFirestoreService.deleteMedicinesResult = (["1"], nil)
        mockFirestoreService.shouldThrowOnDeleteHistory = true
        
        // When
        _ = await sut.deleteMedicines(at: IndexSet(integer: 0))
        
        // Then - History should be restored
        XCTAssertEqual(mockDataStore.history.count, 1)
        XCTAssertEqual(mockDataStore.history[0].medicineId, "1")
        
        // Then - Error should be set
        XCTAssertNotNil(sut.appError)
    }
    
    // MARK: - deleteHistory Tests
    
    func test_deleteHistory_withSuccess_shouldClearAppError() async throws {
        // Given
        sut.appError = AppError.noPermission
        mockDataStore.addHistoryEntries([
            HistoryEntry(id: "h1", medicineId: "1", user: "User1", action: "Ajout", details: "10 units added", timestamp: Date())
        ])
        mockFirestoreService.shouldThrowOnDeleteHistory = false
        
        // When
        try await sut.deleteHistory(for: ["1"])
        
        // Then
        XCTAssertNil(sut.appError)
        XCTAssertEqual(mockDataStore.history.count, 0)
    }
    
    func test_deleteHistory_withError_shouldThrow() async {
        // Given
        mockFirestoreService.shouldThrowOnDeleteHistory = true

        // When / Then
        do {
            try await sut.deleteHistory(for: ["1"])
            XCTFail("Expected deleteHistory to throw an error")
        } catch {
            // Ici, l'erreur est attendue
            let appError = AppError.fromFirestore(error)
            XCTAssertNotNil(appError)
        }
    }
    
    func test_deleteHistory_withEmptyArray_shouldDoNothing() async throws {
        // Given
        mockDataStore.addHistoryEntries([
            HistoryEntry(id: "h1", medicineId: "1", user: "User1", action: "Ajout", details: "10 units added", timestamp: Date())
        ])
        
        // When
        try await sut.deleteHistory(for: [])
        
        // Then
        XCTAssertEqual(mockDataStore.history.count, 1)
        XCTAssertNil(mockFirestoreService.lastDeleteHistoryCollection)
    }
    
    // MARK: - @Published Properties Tests
    
    func test_filterText_shouldPublishChanges() {
        // Given
        let expectation = XCTestExpectation(description: "filterText published")
        var receivedValue: String?
        
        sut.$filterText
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.filterText = "Paracétamol"
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, "Paracétamol")
    }
    
    func test_sortOption_shouldPublishChanges() {
        // Given
        let expectation = XCTestExpectation(description: "sortOption published")
        var receivedValue: Enumerations.SortOption?
        
        sut.$sortOption
            .dropFirst()
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.sortOption = .name
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, .name)
    }
    
    func test_appError_shouldPublishChanges() {
        // Given
        let expectation = XCTestExpectation(description: "appError published")
        var receivedValue: AppError?

        sut.$appError
            .dropFirst()
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.appError = AppError.noPermission

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedValue)
        XCTAssertEqual(receivedValue, .noPermission)
    }
}
