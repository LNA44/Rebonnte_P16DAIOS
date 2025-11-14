//
//  Protocols.swift
//  MediStock
//
//  Created by Ordinateur elena on 13/11/2025.
//

import Foundation
import FirebaseFirestore

protocol FirestoreServicing {
    func fetchMedicines(sortOption: Enumerations.SortOption, filterText: String, completion: @escaping ([Medicine]) -> Void) -> ListenerRegistration
    func fetchMedicine(_ id: String) async -> Medicine?
    func fetchAisles(onUpdate: @escaping ([String]) -> Void) -> ListenerRegistration
    func addMedicine(_ medicine: Medicine, user: String) async throws -> Medicine
    func deleteMedicines(withIds ids: [String]) async -> [String]
    func updateStock(for medicineId: String, newStock: Int) async throws
    func updateMedicine(_ medicine: Medicine) async throws
    func addHistory(action: String,user: String,medicineId: String,details: String) async throws -> HistoryEntry?
    func deleteHistory(for medicineIds: [String]) async throws
}
