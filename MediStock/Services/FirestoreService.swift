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
    
    func fetchMedicinesBatch(sortOption: Enumerations.SortOption,filterText: String, pageSize: Int = 20, lastDocument: DocumentSnapshot? = nil, completion: @escaping ([Medicine], DocumentSnapshot?) -> Void) {
        print("fetchMedicinesBatch appelé")
        
        var query: Query = db.collection("medicines")
        
        // Tri côté serveur
        switch sortOption {
        case .name:
            query = query.order(by: "name", descending: false)
        case .stock:
            query = query.order(by: "stock", descending: false)
        case .none:
            break
        }
        
        // Filtre côté serveur
        if !filterText.isEmpty {
            query = query
                .whereField("name", isGreaterThanOrEqualTo: filterText)
                .whereField("name", isLessThanOrEqualTo: filterText + "\u{f8ff}")
        }
        
        // Pagination
        query = query.limit(to: pageSize)
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching medicines batch: \(error)")
                completion([], nil)
                return
            }
            
            guard let snapshot = snapshot else {
                completion([], nil)
                return
            }
            
            let fetchedMedicines = snapshot.documents.compactMap { doc -> Medicine? in
                try? doc.data(as: Medicine.self)
            }
            
            completion(fetchedMedicines, snapshot.documents.last)
        }
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
    
    func fetchHistoryBatch(for medicineId: String, pageSize: Int = 20, lastDocument: DocumentSnapshot? = nil, completion: @escaping ([HistoryEntry], DocumentSnapshot?) -> Void) {
        var query: Query = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .limit(to: pageSize)
        
        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching history batch: \(error)")
                completion([], nil)
                return
            }
            
            guard let snapshot = snapshot else {
                completion([], nil)
                return
            }
            
            let entries = snapshot.documents.compactMap { doc -> HistoryEntry? in
                var entry = try? doc.data(as: HistoryEntry.self)
                entry?.id = doc.documentID // assure id unique
                return entry
            }
            
            completion(entries, snapshot.documents.last)
        }
    }
    
    func createUser(user: AppUser) async throws {
        let docRef = db.collection("users").document(user.uid)
        do {
            try docRef.setData(from: user)
            print("Utilisateur créé avec succès dans firestore !")
        } catch {
            print("Erreur lors de la création de l'utilisateur : \(error)")
            throw error
        }
    }
    
    func getEmail(uid: String) async throws -> String? {
        let docRef = db.collection("users").document(uid)
        do {
            let document = try await docRef.getDocument()
            let user = try document.data(as: AppUser.self)
            return user.email
        } catch {
            print("Erreur récupération email : \(error)")
            throw error
        }
    }
}
