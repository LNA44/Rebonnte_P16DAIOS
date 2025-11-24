//
//  Protocols.swift
//  MediStock
//
//  Created by Ordinateur elena on 13/11/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

protocol FirestoreServicing {
    func fetchMedicinesBatch(collection: String, sortOption: Enumerations.SortOption,filterText: String?, pageSize: Int, lastDocument: DocumentSnapshotType?, completion: @escaping ([Medicine], DocumentSnapshotType?, Error?) -> Void)
    func fetchAisles(collection: String, onUpdate: @escaping ([String], Error?) -> Void) -> ListenerRegistration
    func addMedicine(collection: String, _ medicine: Medicine, user: String) async throws -> Medicine
    func deleteMedicines(collection: String, withIds ids: [String]) async throws -> [String]
    func updateStock(collection: String,for medicineId: String, newStock: Int) async throws
    func updateMedicine(collection: String,_ medicine: Medicine) async throws
    func addHistory(action: String, user: String,medicineId: String,details: String) async throws -> HistoryEntry?
    func deleteHistory(collection: String, for medicineIds: [String]) async throws
    func fetchHistoryBatch(collection: String,for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshotType?, completion: @escaping ([HistoryEntry], DocumentSnapshotType?, Error?) -> Void)
    func createUser(collection: String, user: AppUser) async throws
    func getEmail(collection: String, uid: String) async throws -> String?
}

protocol AuthServicing {
    func listenToAuthStateChanges(completion: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void)
    func signIn(email: String, password: String, completion: @escaping (AppUser?, Error?)-> Void)
    func signOut() throws
    func removeListener(handle: AuthStateDidChangeListenerHandle?)
}

protocol DocumentSnapshotType {
    var id: String { get }
}
