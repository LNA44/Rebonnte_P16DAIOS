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

            // Appel asynchrone de addHistory
            let historyEntry = try await addHistory(
                action: "Medicine created",
                user: user,
                medicineId: docId,
                details: ""
            )

            if historyEntry != nil {
                print("✅ History créé pour medicine \(docId)")
            }

            return medicineToSave
        } catch {
            print("❌ Error adding medicine: \(error)")
            throw error
        }
    }
    
    func addHistory(action: String,user: String,medicineId: String,details: String) async throws -> HistoryEntry? {
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
}
