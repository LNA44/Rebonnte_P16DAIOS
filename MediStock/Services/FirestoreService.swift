//
//  FirestoreService.swift
//  MediStock
//
//  Created by Ordinateur elena on 12/11/2025.
//

import Foundation
import FirebaseFirestore

class FirestoreService: FirestoreServicing {
    static let shared = FirestoreService()
    private let db: Firestore
    
    private init() {
        db = Firestore.firestore()
    }
    
    func fetchMedicines(sortOption: Enumerations.SortOption, filterText: String, completion: @escaping ([Medicine]) -> Void) -> ListenerRegistration {
        print("fetchMedicines appelé")
        
        var query: Query = db.collection("medicines")
        
        // Appliquer le tri côté serveur
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        if !filterText.isEmpty {
            query = query
                .whereField("name", isGreaterThanOrEqualTo: filterText)
                .whereField("name", isLessThanOrEqualTo: filterText + "\u{f8ff}")
        }
        
        let listener = query.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                completion([])
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchedMedicines = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: Medicine.self)
                } ?? []
                
                DispatchQueue.main.async {
                    completion(fetchedMedicines)
                }
            }
        }
        
        return listener
    }
    
    func fetchMedicine(_ id: String) async -> Medicine? {
        let docRef = db.collection("medicines").document(id)
        
        do {
            let snapshot = try await docRef.getDocument()
            let medicine = try snapshot.data(as: Medicine.self)
            return medicine
        } catch {
            print("Error fetching medicine: \(error)")
            return nil
        }
    }
    
    func fetchAisles(onUpdate: @escaping ([String]) -> Void) -> ListenerRegistration {
        print("fetchAisles appelé")
        
        let listener = db.collection("medicines").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
                onUpdate([])
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let allMedicines = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: Medicine.self)
                    } ?? []
                    
                    let aislesSet = Set(allMedicines.map { $0.aisle })
                    let aislesSorted = Array(aislesSet).sorted()
                    
                    DispatchQueue.main.async {
                        onUpdate(aislesSorted)
                    }
                }
            }
        }
        
        return listener
    }
    
    func addMedicine(_ medicine: Medicine, user: String) async throws -> Medicine {
        print("add medicine appelé")

        let docId = medicine.id ?? UUID().uuidString
        var medicineToSave = medicine
        medicineToSave.id = docId

        do {
            try db.collection("medicines").document(docId).setData(from: medicineToSave)

            print("✅ Medicine ajouté")

            return medicineToSave
        } catch {
            print("❌ Error adding medicine: \(error)")
            throw error
        }
    }
    
    func deleteMedicines(withIds ids: [String]) async -> [String] {
        var deletedIds: [String] = []

        for id in ids {
            do {
                try await db.collection("medicines").document(id).delete()
                print("✅ Successfully deleted medicine with id \(id)")
                deletedIds.append(id)
            } catch {
                print("❌ Error removing document \(id): \(error.localizedDescription)")
            }
        }

        return deletedIds
    }
    
    func updateStock(for medicineId: String, newStock: Int) async throws {
            try await db.collection("medicines").document(medicineId).updateData(["stock": newStock])
        }
    
    func updateMedicine(_ medicine: Medicine) async throws {
            guard let id = medicine.id else { return }
            try db.collection("medicines").document(id).setData(from: medicine)
        }
    
    func addHistory(action: String, user: String,medicineId: String,details: String) async throws -> HistoryEntry? {
        let newId = UUID().uuidString
        let historyEntry = HistoryEntry(
            id: newId,
            medicineId: medicineId,
            user: user,
            action: action,
            details: details
        )

        do {
            print("💾 [addHistory] Envoi vers Firestore...")
            try db.collection("history").document(newId).setData(from: historyEntry)

            print("✅ History ajouté avec succès")
            return historyEntry
        } catch {
            print("❌ Error adding history: \(error)")
            throw error
        }
    }
    
    func deleteHistory(for medicineIds: [String]) async throws {
        guard !medicineIds.isEmpty else { return }
        
        // Firestore limite à 10 valeurs max pour whereField donc on découpe le tableau
        let chunks = medicineIds.chunked(into: 10)
        
        for chunk in chunks {
            let querySnapshot = try await db.collection("history")
                .whereField("medicineId", in: chunk)
                .getDocuments()
            
            // Utiliser un batch pour optimiser les suppressions
            let batch = db.batch()
            
            for document in querySnapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            try await batch.commit()
            
            print("✅ Batch supprimé : \(querySnapshot.documents.count) entrées d'historique")
        }
        
        print("✅ Historique total supprimé pour \(medicineIds.count) médicament(s)")
    }
}
