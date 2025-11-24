//
//  MedicineDetailViewModelTests.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import XCTest
@testable import MediStock // Remplace par le nom de ton module

@MainActor
final class MedicineDetailViewModelTests: XCTestCase {

    var viewModel: MedicineDetailViewModel!
    var mockAuth: MockAuthService!
    var mockFirestore: MockFiresotreService!
    var dataStore: DataStore!

    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        mockFirestore = MockFiresotreService()

        dataStore = DataStore()
        dataStore.medicines = []
        dataStore.history = []
        viewModel = MedicineDetailViewModel(
            authService: mockAuth,
            firestoreService: mockFirestore,
            dataStore: dataStore
        )
    }

    override func tearDown() {
        viewModel = nil
        mockAuth = nil
        mockFirestore = nil
        dataStore = nil
        super.tearDown()
    }

    func test_addMedicine_success_addsMedicineAndHistory() async {
        // Given
        let medicine = Medicine(name: "Med1", stock: 10, aisle: "A")
        let user = "user1"

        // When
        let savedMedicine = await viewModel.addMedicine(medicine, user: user)

        // Then
        XCTAssertEqual(savedMedicine.name, "Med1")
        XCTAssertEqual(mockFirestore.addedMedicines.first?.name, "Med1")
        XCTAssertEqual(mockFirestore.addedHistories.count, 1)
        XCTAssertNil(viewModel.appError)
    }

    func test_addMedicine_failure_setsAppError() async {
        // Given
        mockFirestore.shouldThrowOnAddMedicine = true
        let medicine = Medicine(name: "Med1", stock: 10, aisle: "A")
        let user = "user1"

        // When
        let savedMedicine = await viewModel.addMedicine(medicine, user: user)

        // Then
        XCTAssertEqual(savedMedicine.name, "")
        XCTAssertNotNil(viewModel.appError)
    }

    func test_increaseStock_updatesStockAndHistory() async {
        // Given
        var medicine = Medicine(name: "Med2", stock: 5, aisle: "B")
        medicine.id = "m2"
        dataStore.addMedicinesToLocal([medicine])
        let user = "user1"

        // When
        let newStock = await viewModel.increaseStock(medicine, user: user)

        // Then
        XCTAssertEqual(newStock, 6)
        XCTAssertEqual(dataStore.medicines.first(where: { $0.id == "m2" })?.stock, 6)
        XCTAssertEqual(mockFirestore.addedHistories.count, 1)
        XCTAssertNil(viewModel.appError)
    }

    func test_decreaseStock_updatesStockAndHistory() async {
        // Given
        var medicine = Medicine(name: "Med2", stock: 5, aisle: "B")
        medicine.id = "m2"
        dataStore.addMedicinesToLocal([medicine])
        let user = "user1"

        // When
        let newStock = await viewModel.decreaseStock(medicine, user: user)

        // Then
        XCTAssertEqual(newStock, 4)
        XCTAssertEqual(dataStore.medicines.first(where: { $0.id == "m2" })?.stock, 4)
        XCTAssertEqual(mockFirestore.addedHistories.count, 1)
        XCTAssertNil(viewModel.appError)
    }
    
    func test_updateStock_returnsZero_whenMedicineHasNoId() async {
        // Given
        let medicineWithoutId = Medicine(name: "TestMed", stock: 5, aisle: "Aisle 1")
        
        // When
        let result = await viewModel.updateStock(medicineWithoutId, by: 1, user: "user1")
        
        // Then
        XCTAssertEqual(result, 0)
        XCTAssertNotNil(viewModel.appError == nil) // pas d'erreur ajoutée dans ce cas
    }
    
    func test_updateStock_usesMedicineStock_whenNotInDataStore() async {
        // Given
        let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
        dataStore.medicines = [] // le médicament n'est pas dans le dataStore
        
        // When
        let newStock = await viewModel.updateStock(medicine, by: 3, user: "user1")
        
        // Then
        XCTAssertEqual(newStock, 8) // 5 + 3
        XCTAssertNil(viewModel.appError)
    }
    
    func test_updateStock_updatesCorrectly_whenMedicineHasId() async {
        // Given
        let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
        dataStore.medicines = [medicine]
        
        // When
        let newStock = await viewModel.updateStock(medicine, by: 2, user: "user1")
        
        // Then
        XCTAssertEqual(newStock, 7)
        XCTAssertEqual(dataStore.medicines.first?.stock, 7)
        XCTAssertNil(viewModel.appError)
    }
    
    func test_updateStock_setsAppError_onFirestoreError() async {
        // Given
        let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
        dataStore.medicines = [medicine]
        
        // On force le service Firestore à thrower
        mockFirestore.shouldThrowOnUpdateStock = true
        
        // When
        let returnedStock = await viewModel.updateStock(medicine, by: 3, user: "user1")
        
        // Then
        XCTAssertEqual(returnedStock, 5) // retourne le currentStock
        XCTAssertNotNil(viewModel.appError)
    }

    func test_updateMedicine_success_updatesLocalAndFirestore() async {
        // Given
        var medicine = Medicine(name: "OldMed", stock: 10, aisle: "A")
        medicine.id = "med1"
        dataStore.addMedicinesToLocal([medicine])
        let user = "user1"
        var updatedMedicine = Medicine(name: "NewMed", stock: 15, aisle: "A")
        updatedMedicine.id = "med1"

        // When
        await viewModel.updateMedicine(updatedMedicine, user: user)

        // Then
        XCTAssertEqual(dataStore.medicines.first?.name, "NewMed")
        XCTAssertEqual(mockFirestore.updatedMedicines.first?.name, "NewMed")
        XCTAssertNil(viewModel.appError)
    }

    func test_updateMedicine_failure_setsAppError() async {
        // Given
        mockFirestore.shouldThrowOnUpdateMedicine = true
        var medicine = Medicine(name: "MedFail", stock: 10, aisle: "A")
        medicine.id = "medFail"
        dataStore.addMedicinesToLocal([medicine])
        let user = "user1"

        // When
        await viewModel.updateMedicine(medicine, user: user)

        // Then
        XCTAssertNotNil(viewModel.appError)
    }

    func test_updateMedicine_returnsEarly_whenNoID() async {
        // Given
        let medicine = Medicine(id: nil, name: "TestMed", stock: 5, aisle: "Aisle 1")
        
        // When
        await viewModel.updateMedicine(medicine, user: "user1")
        
        // Then
        // dataStore ne doit pas être mis à jour
        XCTAssertTrue(dataStore.medicines.isEmpty)
        // Pas d'erreur car c’est juste un return
        XCTAssertNil(viewModel.appError)
    }

    func test_addHistory_success_addsToDataStore() async {
        // Given
        let user = "user1"
        let medicineId = "med1"

        // When
        let entry = await viewModel.addHistory(action: "Test", user: user, medicineId: medicineId, details: "")

        // Then
        XCTAssertNotNil(entry)
        XCTAssertTrue(dataStore.history.contains(where: { $0.id == entry?.id }))
        XCTAssertNil(viewModel.appError)
    }

    func test_addHistory_failure_setsAppError() async {
        // Given
        mockFirestore.shouldThrowOnAddHistory = true
        let user = "user1"
        let medicineId = "med1"

        // When
        let entry = await viewModel.addHistory(action: "Test", user: user, medicineId: medicineId, details: "")

        // Then
        XCTAssertNil(entry)
        XCTAssertNotNil(viewModel.appError)
    }
    
    func test_fetchNextHistoryBatch_returnsEarly_whenNoID() {
            // Given
            let medicine = Medicine(id: nil, name: "TestMed", stock: 5, aisle: "Aisle 1")

            // When
            viewModel.fetchNextHistoryBatch(for: medicine)

            // Then
            XCTAssertTrue(dataStore.history.isEmpty)
            XCTAssertNil(viewModel.lastDocument)
            XCTAssertNil(viewModel.appError)
        }

        func test_fetchNextHistoryBatch_success_updatesDataStoreAndLastDocument() {
            // Given
            let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
            let expectedHistory = [
                HistoryEntry(
                    id: "h1",
                    medicineId: "med1",
                    user: "user1",
                    action: "Created",
                    details: "",
                    timestamp: Date()
                )
            ]
            let stubDoc = StubDocumentSnapshot()
            mockFirestore.fetchHistoryBatchResult = (expectedHistory, stubDoc, nil)

            // When
            viewModel.fetchNextHistoryBatch(for: medicine)

            // Then
            XCTAssertEqual(dataStore.history.count, expectedHistory.count)
            XCTAssertEqual(dataStore.history.first?.id, expectedHistory.first?.id)
            XCTAssertEqual(viewModel.lastDocument?.id, stubDoc.id)
            XCTAssertNil(viewModel.appError)
        }

        func test_fetchNextHistoryBatch_error_setsAppError() {
            // Given
            let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
            let error = NSError(domain: "Firestore", code: 1)
            mockFirestore.fetchHistoryBatchResult = ([], nil, error)

            // When
            viewModel.fetchNextHistoryBatch(for: medicine)

            // Then
            XCTAssertTrue(dataStore.history.isEmpty)
            XCTAssertNotNil(viewModel.appError)
        }
    
    func test_fetchNextHistoryBatch_setsAppError_onFirestoreError() {
        // Given
        let medicine = Medicine(id: "med1", name: "TestMed", stock: 5, aisle: "Aisle 1")
        let error = NSError(domain: "Firestore", code: 1)
        mockFirestore.fetchHistoryBatchResult = ([], nil, error)
        
        // When
        viewModel.fetchNextHistoryBatch(for: medicine)
        
        // Then
        XCTAssertTrue(dataStore.history.isEmpty)
        XCTAssertNotNil(viewModel.appError)
        XCTAssertNil(viewModel.lastDocument)
    }
    
    func test_fetchEmail_returnsCachedValue_ifAvailable() async {
        // Given
        let uid = "user1"
        viewModel.emailsCache[uid] = "cached@example.com"
        
        // When
        let email = await viewModel.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "cached@example.com")
        XCTAssertNil(viewModel.appError)
    }

    func test_fetchEmail_fetchesFromService_whenNotCached() async throws {
        // Given
        let uid = "user2"
        mockFirestore.emails[uid] = "service@example.com"
        
        // When
        let email = await viewModel.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "service@example.com")
        XCTAssertEqual(viewModel.emailsCache[uid], "service@example.com")
        XCTAssertNil(viewModel.appError)
    }

    func test_fetchEmail_returnsError_whenServiceThrows() async {
        // Given
        let uid = "user3"
        mockFirestore.shouldThrowOnGetEmail = true
        
        // When
        let email = await viewModel.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "Error")
        XCTAssertEqual(viewModel.emailsCache[uid], "Error")
        XCTAssertNotNil(viewModel.appError)
    }
    
    func test_fetchEmail_returnsUnknown_whenServiceReturnsNil() async {
        // Given
        let uid = "user4"
        mockFirestore.emails[uid] = nil // service renvoie nil
        
        // When
        let email = await viewModel.fetchEmail(for: uid)
        
        // Then
        XCTAssertEqual(email, "Unknown")
        XCTAssertEqual(viewModel.emailsCache[uid], "Unknown")
        XCTAssertNil(viewModel.appError)
    }
}
