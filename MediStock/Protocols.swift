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
    //func fetchMedicines(sortOption: Enumerations.SortOption, filterText: String, completion: @escaping ([Medicine]) -> Void) -> ListenerRegistration
    func fetchMedicinesBatch(sortOption: Enumerations.SortOption,filterText: String, pageSize: Int, lastDocument: DocumentSnapshot?,completion: @escaping ([Medicine], DocumentSnapshot?) -> Void)
    func fetchMedicine(_ id: String) async -> Medicine?
    func fetchAisles(onUpdate: @escaping ([String]) -> Void) -> ListenerRegistration
    func addMedicine(_ medicine: Medicine, user: String) async throws -> Medicine
    func deleteMedicines(withIds ids: [String]) async -> [String]
    func updateStock(for medicineId: String, newStock: Int) async throws
    func updateMedicine(_ medicine: Medicine) async throws
    func addHistory(action: String,user: String,medicineId: String,details: String) async throws -> HistoryEntry?
    func deleteHistory(for medicineIds: [String]) async throws
    func fetchHistoryBatch(for medicineId: String, pageSize: Int, lastDocument: DocumentSnapshot?, completion: @escaping ([HistoryEntry], DocumentSnapshot?) -> Void)
    func createUser(user: AppUser) async throws
    func getEmail(uid: String) async throws -> String?
}

protocol AuthServicing {
    func listenToAuthStateChanges(completion: @escaping (FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle
    func signUp(email: String, password: String, completion: @escaping (AppUser?, Error?) -> Void)
    func signIn(email: String, password: String, completion: @escaping (AppUser?, Error?)-> Void)
    func signOut() throws
    func removeListener(handle: AuthStateDidChangeListenerHandle?)
}
