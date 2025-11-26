//
//  FakeFirestoreIntegrationService.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseFirestore
@testable import MediStock

class FakeFirestoreIntegrationService: FirestoreServicing {
    
    var aisles: [String] = []
    var medicines: [Medicine] = []
    var histories: [HistoryEntry] = []
    var users: [AppUser] = []
    
    var createUserCalled = false
    var createUserCallCount = 0
    
    var medicinesData: [Medicine] = []
    var historiesData: [HistoryEntry] = []
    var deletedMedicineIds: [String] = []
    var deletedHistoryMedicineIds: [String] = []
    
    var shouldThrowOnFetch = false
    var shouldThrowOnDelete = false
    var shouldThrowOnDeleteHistory = false
    var shouldFilterByText = false
    var lastSortOption: Enumerations.SortOption?
    
    // MARK: - fetchAisles
    func fetchAisles(
        collection: String,
        onUpdate: @escaping ([String], Error?) -> Void
    ) -> ListenerRegistration {
        // Simule un "listener" Firestore
        onUpdate(aisles, nil)
        
        // Faux ListenerRegistration
        return FakeListenerRegistration()
    }

    // MARK: - fetchMedicinesBatch
    func fetchMedicinesBatch(
        collection: String,
        sortOption: Enumerations.SortOption,
        filterText: String?,
        pageSize: Int,
        lastDocument: DocumentSnapshotType?,
        completion: @escaping ([Medicine], DocumentSnapshotType?, Error?) -> Void
    ) {
        lastSortOption = sortOption
        
        if shouldThrowOnFetch {
            completion([], nil, NSError(domain: "FetchError", code: 1))
            return
        }
        
        var result = medicinesData
        
        if shouldFilterByText, let filter = filterText {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(filter) }
        }
        
        completion(result, FakeDocumentSnapshot(), nil)
    }

    // MARK: - addMedicine
    func addMedicine(collection: String, _ medicine: Medicine, user: String) async throws -> Medicine {
        var newMedicine = medicine
        newMedicine.id = UUID().uuidString
        medicines.append(newMedicine)
        return newMedicine
    }

    // MARK: - deleteMedicines
    func deleteMedicines(collection: String, withIds ids: [String]) async throws -> [String] {
        if shouldThrowOnDelete {
            throw NSError(domain: "DeleteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated delete error"])
        }
        
        deletedMedicineIds.append(contentsOf: ids)
        medicinesData.removeAll { medicine in
            ids.contains(medicine.id ?? "")
        }
        return ids
    }

    // MARK: - updateStock
    func updateStock(collection: String, for medicineId: String, newStock: Int) async throws {
        guard let index = medicines.firstIndex(where: { $0.id == medicineId }) else { return }
        medicines[index].stock = newStock
    }

    // MARK: - updateMedicine
    func updateMedicine(collection: String, _ medicine: Medicine) async throws {
        guard let index = medicines.firstIndex(where: { $0.id == medicine.id }) else { return }
        medicines[index] = medicine
    }

    // MARK: - addHistory
    func addHistory(collection: String, action: String, user: String, medicineId: String, details: String) async throws -> HistoryEntry? {
        let entry = HistoryEntry(id: UUID().uuidString, medicineId: medicineId, user: user, action: action, details: details, timestamp: Date())
        histories.append(entry)
        return entry
    }

    // MARK: - deleteHistory
    func deleteHistory(collection: String, for medicineIds: [String]) async throws {
        if shouldThrowOnDeleteHistory {
            throw NSError(domain: "DeleteHistoryError", code: 1)
        }
        deletedHistoryMedicineIds.append(contentsOf: medicineIds)
        historiesData.removeAll { medicineIds.contains($0.medicineId) }
    }

    // MARK: - fetchHistoryBatch
    func fetchHistoryBatch(
        collection: String,
        for medicineId: String,
        pageSize: Int,
        lastDocument: DocumentSnapshotType?,
        completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void
    ) {
        let filtered = histories.filter { $0.medicineId == medicineId }
        completion(filtered, nil, nil)
    }

    // MARK: - createUser
    func createUser(collection: String, user: AppUser) async throws {
        createUserCalled = true
        createUserCallCount += 1
        users.append(user)
    }

    // MARK: - getEmail
    func getEmail(collection: String, uid: String) async throws -> String? {
        return "fake@example.com"
    }
    
    // MARK: - reset
    func reset() {
        medicines.removeAll()
        histories.removeAll()
        users.removeAll()
        aisles.removeAll()
        createUserCalled = false
        createUserCallCount = 0
    }
}

// MARK: - Fake listener
final class FakeListenerRegistration: NSObject, ListenerRegistration {
    func remove() { }
}

// MARK: - FakeDocumentSnapshot 

final class FakeDocumentSnapshot: DocumentSnapshotType {
    let id: String
    
    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
