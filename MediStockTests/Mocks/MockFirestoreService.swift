//
//  MockFirestoreService.swift
//  MediStockTests
//
//  Created by Ordinateur elena on 24/11/2025.
//

import Foundation
@testable import MediStock
import FirebaseFirestore

final class MockFiresotreService: FirestoreServicing {

    // MARK: - fetchAisles
    var fetchAislesResult: ([String], Error?)?
    // Le listener last créé (utile pour assertions)
       var lastListener: MockListenerRegistration?
    
    // MARK: - getEmail
        var shouldThrowOnGetEmail = false
        var emails: [String: String] = [:]
    
    // MARK: - createUser
       var shouldThrowOnCreateUser = false
       
    // MARK: - addMedicine
    var shouldThrowOnAddMedicine = false
    var addedMedicines: [Medicine] = []
    
    // MARK: - deleteMedicines
    var deleteMedicinesResult: ([String], Error?)?
    var lastDeleteMedicinesCollection: String?
        var lastDeleteMedicinesIds: [String]?
    
    // MARK: - updateStock
        var shouldThrowOnUpdateStock = false
        var updatedStocks: [(id: String, newStock: Int)] = []
    
    
    // MARK: - updateMedicine
        var shouldThrowOnUpdateMedicine = false
        var updatedMedicines: [Medicine] = []
    
    
    // MARK: - addHistory
       var shouldThrowOnAddHistory = false
       var addedHistories: [HistoryEntry] = []
    
    // MARK: - deleteHistory
       var shouldThrowOnDeleteHistory = false
       var lastDeleteHistoryCollection: String?
       var lastDeleteHistoryMedicineIds: [String]?
    
    // MARK: - fetchMedicinesBatch
    var fetchMedicinesBatchResult: ([Medicine], DocumentSnapshotType?, Error?)?
    var lastFetchMedicinesCollection: String?
    var lastFetchMedicinesFilterText: String?
    var lastFetchMedicinesPageSize: Int?
    var lastFetchMedicinesSortOption: Enumerations.SortOption?
    var lastFetchMedicinesLastDocument: DocumentSnapshotType?
    
    // MARK: - fetchHistoryBatch
        var fetchHistoryBatchResult: ([HistoryEntry], DocumentSnapshotType?, Error?)?
    
    // MARK: - fetchAisles
    func fetchAisles(collection: String, onUpdate: @escaping ([String], Error?) -> Void) -> ListenerRegistration {
        let listener = MockListenerRegistration()
        lastListener = listener

        // Simule l'appel du listener (synchronously to make tests easier)
        if let result = fetchAislesResult {
            onUpdate(result.0, result.1)
        } else {
            // si non défini, renvoie tableau vide
            onUpdate([], nil)
        }

        return listener
    }

    // --- Stubs pour les autres méthodes du protocole (si présents) ---
    func fetchMedicinesBatch(
        collection: String,
        sortOption: Enumerations.SortOption,
        filterText: String?,
        pageSize: Int,
        lastDocument: DocumentSnapshotType?,
        completion: @escaping ([Medicine], DocumentSnapshotType?, Error?) -> Void
    ) {
        lastFetchMedicinesCollection = collection
        lastFetchMedicinesFilterText = filterText
        lastFetchMedicinesPageSize = pageSize
        lastFetchMedicinesSortOption = sortOption
        lastFetchMedicinesLastDocument = lastDocument
        
        if let result = fetchMedicinesBatchResult {
            completion(result.0, result.1, result.2)
        }
    }

    func addMedicine(collection: String, _ medicine: Medicine, user: String) async throws -> Medicine {
            if shouldThrowOnAddMedicine { throw NSError(domain: "Firestore", code: 1) }
            addedMedicines.append(medicine)
            return medicine
        }

    func deleteMedicines(collection: String, withIds ids: [String]) async throws -> [String] {
            lastDeleteMedicinesCollection = collection
            lastDeleteMedicinesIds = ids
            
            if let result = deleteMedicinesResult {
                if let error = result.1 {
                    throw error
                }
                return result.0
            }
            return []
        }
        

    func updateStock(collection: String, for medicineId: String, newStock: Int) async throws {
            if shouldThrowOnUpdateStock { throw NSError(domain: "Firestore", code: 2) }
            updatedStocks.append((medicineId, newStock))
        }
    
    func updateMedicine(collection: String, _ medicine: Medicine) async throws {
           if shouldThrowOnUpdateMedicine { throw NSError(domain: "Firestore", code: 3) }
           updatedMedicines.append(medicine)
       }
    
    func addHistory(action: String, user: String, medicineId: String, details: String) async throws -> HistoryEntry? {
            if shouldThrowOnAddHistory { throw NSError(domain: "Firestore", code: 4) }
            let entry = HistoryEntry(id: UUID().uuidString, medicineId: medicineId, user: user, action: action, details: details)
            addedHistories.append(entry)
            return entry
        }
    
    func deleteHistory(collection: String, for medicineIds: [String]) async throws {
            lastDeleteHistoryCollection = collection
            lastDeleteHistoryMedicineIds = medicineIds
            
            if shouldThrowOnDeleteHistory {
                throw NSError(domain: "MockError", code: 500)
            }
        }
    func fetchHistoryBatch(collection: String, for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshotType?, completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void) {
        if let (entries, stubDoc, error) = fetchHistoryBatchResult {
                    completion(entries, stubDoc, error) 
                }
       }

    func createUser(collection: String, user: AppUser) async throws {
        if shouldThrowOnCreateUser {
            throw NSError(domain: "Firestore", code: 1)
        }
    }

    func getEmail(collection: String, uid: String) async throws -> String? {
            if shouldThrowOnGetEmail { throw NSError(domain: "Firestore", code: 5) }
            return emails[uid]
        }
}

