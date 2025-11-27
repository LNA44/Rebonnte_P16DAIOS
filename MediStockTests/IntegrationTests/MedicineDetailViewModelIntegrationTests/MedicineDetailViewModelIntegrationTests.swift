//
//  MedicineDetailViewModelIntegrationTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
import Combine
@testable import MediStock

@MainActor
final class MedicineDetailViewModelIntegrationTests: XCTestCase {
    
    var sut: MedicineDetailViewModel!
    var fakeAuthService: FakeAuthIntegrationService!
    var fakeFirestoreService: FakeFirestoreIntegrationService!
    var dataStore: DataStore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        fakeAuthService = FakeAuthIntegrationService()
        fakeFirestoreService = FakeFirestoreIntegrationService()
        dataStore = DataStore()

        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreService,
            dataStore: dataStore
        )
        
        cancellables = []
    }
    
    override func tearDown() async throws {
        sut = nil
        fakeAuthService = nil
        fakeFirestoreService = nil
        dataStore = nil
        cancellables = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests addMedicine
    
    func test_addMedicine_withValidData_shouldAddMedicineAndCreateHistory() async {
        // Given
        let medicine = Medicine(name: "Aspirin", stock: 10, aisle: "A1")
        let user = "user123"
        
        // When
        let result = await sut.addMedicine(medicine, user: user)
        
        // Then
        XCTAssertNotNil(result.id, "Medicine should have an ID")
        XCTAssertEqual(result.name, "Aspirin")
        XCTAssertEqual(result.stock, 10)
        
        // Vérifier que le médicament est dans Firestore fake
        XCTAssertEqual(fakeFirestoreService.medicines.count, 1)
        XCTAssertEqual(fakeFirestoreService.medicines.first?.name, "Aspirin")
        
        // Vérifier que l'historique a été créé
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        XCTAssertEqual(fakeFirestoreService.histories.first?.action, "Medicine created")
        XCTAssertEqual(fakeFirestoreService.histories.first?.user, user)
        
        // Vérifier que le DataStore local est mis à jour
        XCTAssertEqual(dataStore.history.count, 1)
        
        // Vérifier qu'il n'y a pas d'erreur
        XCTAssertNil(sut.appError)
    }
    
    func test_addMedicine_withFirestoreError_shouldSetAppError() async {
        // Given
        let medicine = Medicine(name: "Error Medicine", stock: 5, aisle: "B2")
        let user = "user123"
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        // When
        let result = await sut.addMedicine(medicine, user: user)
        
        // Then
        XCTAssertNil(result.id, "Medicine shouldn't have an ID in case of error")
        XCTAssertNotNil(sut.appError, "An error should appear")
        XCTAssertEqual(dataStore.history.count, 0, "History shouldn't be created in case of error")
    }
    
    // MARK: - Tests increaseStock
    
    func test_increaseStock_shouldIncreaseByOne() async {
        // Given
        let medicine = Medicine(id: "med1", name: "Paracetamol", stock: 5, aisle: "C3")
        dataStore.medicines = [medicine]
        fakeFirestoreService.medicines = [medicine]
        let user = "user123"
        
        // When
        let newStock = await sut.increaseStock(medicine, user: user)
        
        // Then
        XCTAssertEqual(newStock, 6, "Stock should increase by one")
        let updatedInFirestore = fakeFirestoreService.medicines.first { $0.id == "med1" }
        XCTAssertEqual(updatedInFirestore?.stock, 6)
        let updatedLocal = dataStore.medicines.first { $0.id == "med1" }
        XCTAssertEqual(updatedLocal?.stock, 6)
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        XCTAssertTrue(fakeFirestoreService.histories.first?.action.contains("Increased") ?? false)
        
        XCTAssertNil(sut.appError)
    }
    
    // MARK: - Tests decreaseStock
    
    func test_decreaseStock_shouldDecreaseByOne() async {
        // Given
        let medicine = Medicine(id: "med2", name: "Ibuprofen", stock: 10, aisle: "D4")
        dataStore.medicines = [medicine]
        fakeFirestoreService.medicines = [medicine]
        let user = "user456"
        
        // When
        let newStock = await sut.decreaseStock(medicine, user: user)
        
        // Then
        XCTAssertEqual(newStock, 9, "Stock should decrease by one")
        let updatedInFirestore = fakeFirestoreService.medicines.first { $0.id == "med2" }
        XCTAssertEqual(updatedInFirestore?.stock, 9)
        let updatedLocal = dataStore.medicines.first { $0.id == "med2" }
        XCTAssertEqual(updatedLocal?.stock, 9)
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        XCTAssertTrue(fakeFirestoreService.histories.first?.action.contains("Decreased") ?? false)
        XCTAssertNil(sut.appError)
    }
    
    // MARK: - Tests updateStock
    
    func test_updateStock_withPositiveAmount_shouldUpdateCorrectly() async {
        // Given
        let medicine = Medicine(id: "med3", name: "Vitamin C", stock: 20, aisle: "E5")
        dataStore.medicines = [medicine]
        let user = "user789"
        let amount = 5
        
        // When
        let newStock = await sut.updateStock(medicine, by: amount, user: user)
        
        // Then
        XCTAssertEqual(newStock, 25, "Stock should be 20+5=25")
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        let history = fakeFirestoreService.histories.first
        XCTAssertTrue(history?.details.contains("from 20 to 25") ?? false)
        XCTAssertNil(sut.appError)
    }
    
    func test_updateStock_withNegativeAmount_shouldUpdateCorrectly() async {
        // Given
        let medicine = Medicine(id: "med4", name: "Cough Syrup", stock: 15, aisle: "F6")
        dataStore.medicines = [medicine]
        let user = "user789"
        let amount = -3
        
        // When
        let newStock = await sut.updateStock(medicine, by: amount, user: user)
        
        // Then
        XCTAssertEqual(newStock, 12, "Stock should be 15 - 3 = 12")
        XCTAssertNil(sut.appError)
    }
    
    func test_updateStock_withFirestoreError_shouldReturnCurrentStock() async {
        // Given
        let medicine = Medicine(id: "med5", name: "Bandages", stock: 8, aisle: "G7")
        dataStore.medicines = [medicine]
        let user = "user123"
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        // When
        let newStock = await sut.updateStock(medicine, by: 2, user: user)
        
        // Then
        XCTAssertEqual(newStock, 8, "Stock should remain the same")
        XCTAssertNotNil(sut.appError, "An error should appear")
    }
    
    func test_updateStock_withoutMedicineId_shouldReturnZero() async {
        // Given
        let medicine = Medicine(name: "No ID Medicine", stock: 10, aisle: "H8")
        let user = "user123"
        
        // When
        let newStock = await sut.updateStock(medicine, by: 5, user: user)
        
        // Then
        XCTAssertEqual(newStock, 0, "Without ID the method should return 0")
    }
    
    // MARK: - Tests updateMedicine
    
    func test_updateMedicine_withHistoryEnabled_shouldUpdateAndCreateHistory() async {
        // Given
        let medicine = Medicine(id: "med6", name: "Aspirin Updated", stock: 15, aisle: "A1")
        dataStore.medicines = [Medicine(id: "med6", name: "Aspirin", stock: 10, aisle: "A1")]
        fakeFirestoreService.medicines = [Medicine(id: "med6", name: "Aspirin", stock: 10, aisle: "A1")]
        let user = "user123"
        
        // When
        await sut.updateMedicine(medicine, user: user, shouldAddHistory: true)
        
        // Then
        let updatedInFirestore = fakeFirestoreService.medicines.first { $0.id == "med6" }
        XCTAssertEqual(updatedInFirestore?.name, "Aspirin Updated")
        XCTAssertEqual(updatedInFirestore?.stock, 15)
        let updatedLocal = dataStore.medicines.first { $0.id == "med6" }
        XCTAssertEqual(updatedLocal?.name, "Aspirin Updated")
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        XCTAssertTrue(fakeFirestoreService.histories.first?.action.contains("Updated") ?? false)
        XCTAssertNil(sut.appError)
    }
    
    func test_updateMedicine_withHistoryDisabled_shouldNotCreateHistory() async {
        // Given
        let medicine = Medicine(id: "med7", name: "Paracetamol Updated", stock: 20, aisle: "B2")
        dataStore.medicines = [Medicine(id: "med7", name: "Paracetamol", stock: 15, aisle: "B2")]
        fakeFirestoreService.medicines = [Medicine(id: "med7", name: "Paracetamol", stock: 15, aisle: "B2")]
        
        let user = "user456"
        
        // When
        await sut.updateMedicine(medicine, user: user, shouldAddHistory: false)
        
        // Then
        let updatedInFirestore = fakeFirestoreService.medicines.first { $0.id == "med7" }
        XCTAssertEqual(updatedInFirestore?.name, "Paracetamol Updated")
        XCTAssertEqual(fakeFirestoreService.histories.count, 0)
        XCTAssertEqual(dataStore.history.count, 0)
        
        XCTAssertNil(sut.appError)
    }
    
    func test_updateMedicine_withFirestoreError_shouldSetAppError() async {
        // Given
        let medicine = Medicine(id: "med8", name: "Error Medicine", stock: 5, aisle: "C3")
        let user = "user123"
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        // When
        await sut.updateMedicine(medicine, user: user)
        
        // Then
        XCTAssertNotNil(sut.appError, "An error should appear")
    }
    
    func test_updateMedicine_withoutId_shouldNotUpdate() async {
        // Given
        let medicine = Medicine(name: "No ID", stock: 10, aisle: "D4")
        let user = "user123"
        
        let initialCount = fakeFirestoreService.medicines.count
        
        // When
        await sut.updateMedicine(medicine, user: user)
        
        // Then
        XCTAssertEqual(fakeFirestoreService.medicines.count, initialCount,
                       "No medicine should be updated without an ID")
    }
    
    // MARK: - Tests addHistory
    
    func test_addHistory_shouldCreateHistoryEntry() async {
        // Given
        let action = "Test Action"
        let user = "user123"
        let medicineId = "med1"
        let details = "Test details"
        
        // When
        let result = await sut.addHistory(
            action: action,
            user: user,
            medicineId: medicineId,
            details: details
        )
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.action, action)
        XCTAssertEqual(result?.user, user)
        XCTAssertEqual(result?.medicineId, medicineId)
        XCTAssertEqual(result?.details, details)
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
        XCTAssertEqual(dataStore.history.count, 1)
        XCTAssertNil(sut.appError)
    }
    
    func test_addHistory_withFirestoreError_shouldReturnNil() async {
        // Given
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        // When
        let result = await sut.addHistory(
            action: "Error Action",
            user: "user123",
            medicineId: "med1",
            details: "Should fail"
        )
        
        // Then
        XCTAssertNil(result)
        XCTAssertNotNil(sut.appError)
        XCTAssertEqual(dataStore.history.count, 0)
    }
    
    // MARK: - Tests fetchNextHistoryBatch
    
    func test_fetchNextHistoryBatch_shouldFetchHistoryForMedicine() {
        // Given
        let medicine = Medicine(id: "med1", name: "Aspirin", stock: 10, aisle: "A1")
        
        // Pré-remplir l'historique dans le fake
        let entries = [
            HistoryEntry(id: "h1", medicineId: "med1", user: "user1", action: "Created", details: "", timestamp: Date()),
            HistoryEntry(id: "h2", medicineId: "med1", user: "user2", action: "Updated", details: "", timestamp: Date())
        ]
        fakeFirestoreService.histories = entries
        
        let expectation = expectation(description: "Fetch history")
        
        // Observer le DataStore
        var historyReceived = false
        dataStore.$history
            .dropFirst()
            .sink { history in
                if history.count == 2 {
                    historyReceived = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.fetchNextHistoryBatch(for: medicine, pageSize: 20)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertTrue(historyReceived)
        XCTAssertEqual(dataStore.history.count, 2)
        XCTAssertNil(sut.appError)
    }
    
    func test_fetchNextHistoryBatch_withoutMedicineId_shouldNotFetch() {
        // Given
        let medicine = Medicine(name: "No ID", stock: 10, aisle: "A1")
        let initialCount = dataStore.history.count
        
        // When
        sut.fetchNextHistoryBatch(for: medicine)
        
        // Then
        XCTAssertEqual(dataStore.history.count, initialCount)
    }
    
    func test_fetchNextHistoryBatch_withError_shouldSetAppError() {
        // Given
        let medicine = Medicine(id: "med1", name: "Aspirin", stock: 10, aisle: "A1")
        
        // Simuler une erreur dans le fake
        let expectation = expectation(description: "Error handling")
        
        // Version simple: créer un fake qui retourne une erreur
        final class FakeFirestoreServiceWithFetchError: FakeFirestoreIntegrationService {
            override func fetchHistoryBatch(
                collection: String,
                for medicineId: String,
                pageSize: Int,
                lastDocument: DocumentSnapshotType?,
                completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void
            ) {
                let error = NSError(domain: "FirestoreError", code: 1)
                completion([], nil, error)
            }
        }
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithFetchError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        sut.$appError
            .dropFirst()
            .sink { error in
                if error != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.fetchNextHistoryBatch(for: medicine)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(sut.appError)
    }
    
    func test_fetchNextHistoryBatch_withPagination_shouldUpdateLastDocument() {
        // Given
        let medicine = Medicine(id: "med1", name: "Aspirin", stock: 10, aisle: "A1")
        
        // Simuler un document de pagination
        final class FakePaginationFirestoreService: FakeFirestoreIntegrationService {
            override func fetchHistoryBatch(
                collection: String,
                for medicineId: String,
                pageSize: Int,
                lastDocument: DocumentSnapshotType?,
                completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void
            ) {
                let entries = [
                    HistoryEntry(id: "h1", medicineId: medicineId, user: "user1", action: "Action", details: "", timestamp: Date())
                ]
                let fakeDoc = FakeDocumentSnapshot()
                completion(entries, fakeDoc, nil)
            }
        }
        
        let fakePaginationService = FakePaginationFirestoreService()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakePaginationService,
            dataStore: dataStore
        )
        
        let expectation = expectation(description: "Pagination")
        
        dataStore.$history
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        XCTAssertNil(sut.lastDocument)
        sut.fetchNextHistoryBatch(for: medicine)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(sut.lastDocument)
    }
    
    // MARK: - Tests fetchEmail
    
    func test_fetchEmail_shouldReturnEmail() async {
        // Given
        let uid = "user123"
        
        // When
        let email = await sut.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "fake@example.com")
        XCTAssertEqual(sut.emailsCache[uid], "fake@example.com")
        XCTAssertNil(sut.appError)
    }
    
    func test_fetchEmail_withCachedEmail_shouldReturnCachedValue() async {
        // Given
        let uid = "user456"
        sut.emailsCache[uid] = "cached@example.com"
        
        // When
        let email = await sut.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "cached@example.com")
    }
    
    func test_fetchEmail_withFirestoreError_shouldReturnError() async {
        // Given
        let uid = "error-user"
        
        let fakeFirestoreWithError = FakeFirestoreServiceWithError()
        sut = MedicineDetailViewModel(
            authService: fakeAuthService,
            firestoreService: fakeFirestoreWithError,
            dataStore: dataStore
        )
        
        // When
        let email = await sut.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "Error")
        XCTAssertEqual(sut.emailsCache[uid], "Error")
        XCTAssertNotNil(sut.appError)
    }
    
    func test_fetchEmail_multipleCalls_shouldCacheCorrectly() async {
        // Given
        let uid1 = "user1"
        let uid2 = "user2"
        
        // When
        let email1 = await sut.fetchEmail(for: uid1)
        let email2 = await sut.fetchEmail(for: uid2)
        let email1Again = await sut.fetchEmail(for: uid1)
        
        // Then
        XCTAssertEqual(email1, "fake@example.com")
        XCTAssertEqual(email2, "fake@example.com")
        XCTAssertEqual(email1Again, "fake@example.com")
        XCTAssertEqual(sut.emailsCache.count, 2)
    }
    
    // MARK: - Tests d'intégration complexes
    
    func test_completeFlow_addMedicineAndUpdateStock() async {
        // Given
        let medicine = Medicine(name: "Complete Flow Medicine", stock: 10, aisle: "Z9")
        let user = "user123"
        
        // When - Ajouter un médicament
        let addedMedicine = await sut.addMedicine(medicine, user: user)
        
        //Synchroniser manuellement (simule ce que fetchMedicinesBatch fait)
            dataStore.addMedicinesToLocal(fakeFirestoreService.medicines)
        
        // Then - Vérifier l'ajout
        XCTAssertNotNil(addedMedicine.id)
        XCTAssertEqual(fakeFirestoreService.histories.count, 1)
                
        // When - Augmenter le stock
        let newStock = await sut.increaseStock(addedMedicine, user: user)
        
        // Then - Vérifier l'augmentation
        XCTAssertEqual(newStock, 11)
        XCTAssertEqual(fakeFirestoreService.histories.count, 2)
        
        // ✅ Récupérer le médicament mis à jour
        guard let updatedMedicine = dataStore.medicines.first(where: { $0.id == addedMedicine.id }) else {
            XCTFail("Medicine not found in dataStore")
            return
        }
        XCTAssertEqual(updatedMedicine.stock, 11)
        
        // When - Diminuer le stock
        let finalStock = await sut.decreaseStock(updatedMedicine, user: user)

        // Then - Vérifier la diminution
        XCTAssertEqual(finalStock, 10)
        XCTAssertEqual(fakeFirestoreService.histories.count, 3)
        
        XCTAssertNil(sut.appError)
    }
    
    func test_concurrentOperations_shouldHandleCorrectly() async {
        // Given
        let medicine1 = Medicine(name: "Concurrent 1", stock: 5, aisle: "A1")
        let medicine2 = Medicine(name: "Concurrent 2", stock: 8, aisle: "B2")
        let user = "user123"
        
        // When - Opérations concurrentes
        let result1 = await sut.addMedicine(medicine1, user: user)
        let result2 = await sut.addMedicine(medicine2, user: user)
        
        let (med1, med2) = (result1, result2)
        
        // Then
        XCTAssertNotNil(med1.id)
        XCTAssertNotNil(med2.id)
        XCTAssertEqual(fakeFirestoreService.medicines.count, 2)
        XCTAssertEqual(fakeFirestoreService.histories.count, 2)
    }
}

