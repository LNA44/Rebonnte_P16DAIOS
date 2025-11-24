//
//  FakeFirestoreServiceWithError.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
import FirebaseFirestore
@testable import MediStock

final class FakeFirestoreServiceWithError: FirestoreServicing {
    
    var aisles: [String] = []
    var medicines: [Medicine] = []
    var histories: [HistoryEntry] = []
    
    func fetchAisles(collection: String, onUpdate: @escaping ([String], Error?) -> Void) -> ListenerRegistration {
        onUpdate([], nil)
        return FakeListenerRegistration()
    }
    
    func fetchMedicinesBatch(collection: String, sortOption: Enumerations.SortOption, filterText: String?, pageSize: Int, lastDocument: DocumentSnapshotType?, completion: @escaping ([Medicine], DocumentSnapshotType?, Error?) -> Void) {
            let error = NSError(domain: "FirestoreError", code: 1)
            completion([], nil, error)
        }
    
    func addMedicine(collection: String, _ medicine: Medicine, user: String) async throws -> Medicine {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func deleteMedicines(collection: String, withIds ids: [String]) async throws -> [String] {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func updateStock(collection: String, for medicineId: String, newStock: Int) async throws {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func updateMedicine(collection: String, _ medicine: Medicine) async throws {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func addHistory(action: String, user: String, medicineId: String, details: String) async throws -> HistoryEntry? {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func deleteHistory(collection: String, for medicineIds: [String]) async throws {
        throw NSError(domain: "FirestoreError", code: 1)
    }
    
    func fetchHistoryBatch(collection: String, for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshotType?, completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void) {
           let error = NSError(domain: "FirestoreError", code: 1)
           completion([], nil, error)
       }
    
    func createUser(collection: String, user: AppUser) async throws {
        throw NSError(domain: "FirestoreError", code: 14, userInfo: [
            NSLocalizedDescriptionKey: "Permission denied"
        ])
    }
    
    func getEmail(collection: String, uid: String) async throws -> String? {
        throw NSError(domain: "FirestoreError", code: 1)
    }
}
