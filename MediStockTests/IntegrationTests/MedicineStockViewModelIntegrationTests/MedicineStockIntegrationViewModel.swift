//
//  MedicineStockIntegrationViewModel.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
@testable import MediStock

@MainActor
final class MedicineStockViewModelIntegrationTests: XCTestCase {
    
    var sut: MedicineStockViewModel!
    var fakeFirestoreService: FakeFirestoreIntegrationService!
    var dataStore: DataStore!
    
    override func setUp() {
        super.setUp()
        fakeFirestoreService = FakeFirestoreIntegrationService()
        dataStore = DataStore()
        sut = MedicineStockViewModel(
            firestoreService: fakeFirestoreService,
            dataStore: dataStore
        )
    }
    
    override func tearDown() {
        sut = nil
        fakeFirestoreService = nil
        dataStore = nil
        super.tearDown()
    }
    
    // MARK: - Fetch Tests
    
    func test_fetchNextMedicinesBatch_withNoFilter_shouldAddMedicinesToDataStore() {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Aspirine", stock: 10, aisle: "A1"),
            Medicine(id: "med2", name: "Paracetamol", stock: 5, aisle: "B2")
        ]
        fakeFirestoreService.medicinesData = medicines
        
        // When
        sut.fetchNextMedicinesBatch(pageSize: 20)
        
        // Then
        XCTAssertEqual(dataStore.medicines.count, 2)
        XCTAssertEqual(dataStore.medicines.first?.name, "Aspirine")
        XCTAssertEqual(dataStore.medicines.first?.aisle, "A1")
        XCTAssertNil(sut.appError)
    }
    
    func test_fetchNextMedicinesBatch_withFilter_shouldAddFilteredMedicines() {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Aspirine", stock: 10, aisle: "A1"),
            Medicine(id: "med2", name: "Paracétamol", stock: 5, aisle: "B2")
        ]
        fakeFirestoreService.medicinesData = medicines
        fakeFirestoreService.shouldFilterByText = true
        
        // When
        sut.fetchNextMedicinesBatch(pageSize: 20, filterText: "Aspi")
        
        // Then
        XCTAssertEqual(dataStore.medicines.count, 1)
        XCTAssertEqual(dataStore.medicines.first?.name, "Aspirine")
        XCTAssertNil(sut.appError)
    }
    
    func test_fetchNextMedicinesBatch_onError_shouldSetAppError() {
        // Given
        fakeFirestoreService.shouldThrowOnFetch = true
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertNotNil(sut.appError)
        XCTAssertEqual(dataStore.medicines.count, 0)
    }
    
    func test_fetchNextMedicinesBatch_multipleCalls_shouldPaginate() {
        // Given
        let batch1 = [
            Medicine(id: "med1", name: "Med1", stock: 10, aisle: "A1")
        ]
        let batch2 = [
            Medicine(id: "med2", name: "Med2", stock: 5, aisle: "B2")
        ]
        
        fakeFirestoreService.medicinesData = batch1
        
        // When - Premier batch
        sut.fetchNextMedicinesBatch(pageSize: 1)
        
        // Then
        XCTAssertEqual(dataStore.medicines.count, 1)
        XCTAssertNotNil(sut.lastMedicinesDocument)
        
        // Given - Deuxième batch
        fakeFirestoreService.medicinesData = batch2
        
        // When - Deuxième appel
        sut.fetchNextMedicinesBatch(pageSize: 1)
        
        // Then
        XCTAssertEqual(dataStore.medicines.count, 2)
    }
    
    func test_fetchNextMedicinesBatch_shouldSetNameLowercase() {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Aspirine", stock: 10, aisle: "A1")
        ]
        fakeFirestoreService.medicinesData = medicines
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(dataStore.medicines.first?.name_lowercase, "aspirine")
    }
    
    // MARK: - Delete Tests
    
    func test_deleteMedicines_shouldRemoveFromDataStoreAndFirestore() async {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Med1", stock: 10, aisle: "A1"),
            Medicine(id: "med2", name: "Med2", stock: 5, aisle: "B2")
        ]
        dataStore.medicines = medicines
        fakeFirestoreService.medicinesData = medicines
        
        let indexSet = IndexSet(integer: 0)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertEqual(deletedIds.count, 1)
        XCTAssertEqual(deletedIds.first, "med1")
        XCTAssertEqual(dataStore.medicines.count, 1)
        XCTAssertEqual(dataStore.medicines.first?.id, "med2")
        XCTAssertTrue(fakeFirestoreService.deletedMedicineIds.contains("med1"))
        XCTAssertNil(sut.appError)
    }
    
    func test_deleteMedicines_multipleItems_shouldDeleteAll() async {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Med1", stock: 10, aisle: "A1"),
            Medicine(id: "med2", name: "Med2", stock: 5, aisle: "B2"),
            Medicine(id: "med3", name: "Med3", stock: 8, aisle: "C3")
        ]
        dataStore.medicines = medicines
        fakeFirestoreService.medicinesData = medicines
        
        let indexSet = IndexSet([0, 2]) // Delete med1 and med3
        
        // When
        let deletedIds = await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertEqual(deletedIds.count, 2)
        XCTAssertTrue(deletedIds.contains("med1"))
        XCTAssertTrue(deletedIds.contains("med3"))
        XCTAssertEqual(dataStore.medicines.count, 1)
        XCTAssertEqual(dataStore.medicines.first?.id, "med2")
        XCTAssertNil(sut.appError)
    }
    
    func test_deleteMedicines_onError_shouldSetAppErrorAndKeepLocalData() async {
        // Given
        let medicines = [
            Medicine(id: "med1", name: "Med1", stock: 10, aisle: "A1")
        ]
        dataStore.medicines = medicines
        fakeFirestoreService.shouldThrowOnDelete = true
        
        let indexSet = IndexSet(integer: 0)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertEqual(deletedIds.count, 0, "No ID returned in case of an error")
        XCTAssertNotNil(sut.appError, "An error should be defined")
        
        // ✅ Les données locales doivent être PRÉSERVÉES car Firestore a échoué
        XCTAssertEqual(dataStore.medicines.count, 1, "Data must not be deleted")
        XCTAssertEqual(dataStore.medicines.first?.id, "med1")
    }
    
    func test_deleteMedicines_withoutId_shouldHandleGracefully() async {
        // Given
        let medicines = [
            Medicine(name: "Med1", stock: 10, aisle: "A1"), // Pas d'ID
            Medicine(id: "med2", name: "Med2", stock: 5, aisle: "B2")
        ]
        dataStore.medicines = medicines
        
        let indexSet = IndexSet(integer: 0)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertEqual(deletedIds.count, 0) // Pas d'ID = pas de suppression Firestore
        XCTAssertEqual(dataStore.medicines.count, 1) // Supprimé localement quand même
    }
    
    // MARK: - Delete History Tests
    
    func test_deleteHistory_shouldRemoveHistoryFromDataStoreAndFirestore() async throws {
        // Given
        let medicineIds = ["med1", "med2"]
        let histories = [
            HistoryEntry(id: "hist1", medicineId: "med1", user: "Created", action: "user1", details: "", timestamp: Date()),
            HistoryEntry(id: "hist2", medicineId: "med2", user: "Updated", action: "user1", details: "", timestamp: Date()),
            HistoryEntry(id: "hist3", medicineId: "med3", user: "Created", action: "user1", details: "", timestamp: Date()),
        ]
        dataStore.history = histories
        fakeFirestoreService.historiesData = histories
        
        // When
        try await sut.deleteHistory(for: medicineIds)
        
        // Then
        XCTAssertEqual(dataStore.history.count, 1)
        XCTAssertEqual(dataStore.history.first?.medicineId, "med3")
        XCTAssertTrue(fakeFirestoreService.deletedHistoryMedicineIds.contains("med1"))
        XCTAssertTrue(fakeFirestoreService.deletedHistoryMedicineIds.contains("med2"))
        XCTAssertNil(sut.appError)
    }
    
    func test_deleteHistory_withEmptyArray_shouldDoNothing() async throws {
        // Given
        let histories = [
            HistoryEntry(id: "hist1", medicineId: "med1", user: "Created", action: "user1", details: "", timestamp: Date())
        ]
        dataStore.history = histories
        
        // When
        try await sut.deleteHistory(for: [])
        
        // Then
        XCTAssertEqual(dataStore.history.count, 1)
        XCTAssertEqual(fakeFirestoreService.deletedHistoryMedicineIds.count, 0)
    }
    
    func test_deleteHistory_onError_shouldThrowError() async {
        // Given
        fakeFirestoreService.shouldThrowOnDeleteHistory = true
        
        // When/Then
        do {
            try await sut.deleteHistory(for: ["med1"])
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Integration Flow Tests
    
    func test_fullDeleteFlow_shouldDeleteMedicineAndHistory() async {
        // Given
        let medicine = Medicine(id: "med1", name: "Med1", stock: 10, aisle: "A1")
        let history = HistoryEntry(id: "hist1", medicineId: "med1", user: "Created", action: "user1", details: "", timestamp: Date())
        
        dataStore.medicines = [medicine]
        dataStore.history = [history]
        fakeFirestoreService.medicinesData = [medicine]
        fakeFirestoreService.historiesData = [history]
        
        let indexSet = IndexSet(integer: 0)
        
        // When
        let deletedIds = await sut.deleteMedicines(at: indexSet)
        
        // Then - Medicine supprimé
        XCTAssertEqual(deletedIds.count, 1)
        XCTAssertEqual(dataStore.medicines.count, 0)
        
        // Then - History supprimé
        XCTAssertEqual(dataStore.history.count, 0)
        XCTAssertTrue(fakeFirestoreService.deletedHistoryMedicineIds.contains("med1"))
        XCTAssertNil(sut.appError)
    }
    
    func test_sortOption_shouldBeAppliedInFetch() {
        // Given
        sut.sortOption = .name
        let medicines = [
            Medicine(id: "med1", name: "Zinc", stock: 10, aisle: "Z9"),
            Medicine(id: "med2", name: "Aspirine", stock: 5, aisle: "A1")
        ]
        fakeFirestoreService.medicinesData = medicines
        
        // When
        sut.fetchNextMedicinesBatch()
        
        // Then
        XCTAssertEqual(fakeFirestoreService.lastSortOption, .name)
        XCTAssertNotNil(dataStore.medicines)
    }
    
    func test_filterText_shouldBeStoredInViewModel() {
        // Given
        let filterText = "Aspirine"
        
        // When
        sut.filterText = filterText
        
        // Then
        XCTAssertEqual(sut.filterText, "Aspirine")
    }
}
