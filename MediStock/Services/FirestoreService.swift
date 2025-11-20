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
    
    func fetchMedicinesBatch(collection: String, sortOption: Enumerations.SortOption,filterText: String? = nil, pageSize: Int = 20, lastDocument: DocumentSnapshot? = nil, completion: @escaping ([Medicine], DocumentSnapshot?) -> Void) {
        var query: Query = db.collection(collection)

        let hasFilter = filterText != nil && !filterText!.isEmpty

        // Filtre + tri côté serveur
        if hasFilter {
            let filterLower = filterText!.lowercased()
            
            // Filtre par name_lowercase
            query = query
                .whereField("name_lowercase", isGreaterThanOrEqualTo: filterLower)
                .whereField("name_lowercase", isLessThanOrEqualTo: filterLower + "\u{f8ff}")
            
            // Ajouter le tri selon l'option
            switch sortOption {
            case .name:
                query = query.order(by: "name_lowercase", descending: false)
                print("✅ Filtre par nom + tri par nom appliqués")
                
            case .stock:
                // Utilise l'index composite : name_lowercase + stock
                query = query
                    .order(by: "name_lowercase", descending: false) // Nécessaire pour le filtre
                    .order(by: "stock", descending: true)           // Tri secondaire par stock
                print("✅ Filtre par nom + tri par stock appliqués (index composite)")
                
            case .none:
                query = query.order(by: "name_lowercase", descending: false)
                print("✅ Filtre par nom appliqué")
            }
        } else {
            
            // Aucun filtre → tri normal
            switch sortOption {
            case .name:
                print("📝 Tri par NOM")
                query = query.order(by: "name_lowercase")

            case .stock:
                print("📦 Tri par STOCK")
                query = query.order(by: "stock", descending: true)

            case .none:
                print("⚪ Aucun tri")
            }
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
    
    
    func fetchMedicine(_ id: String, collection: String = "medicines") async -> Medicine? {
        let docRef = db.collection(collection).document(id)
        
        do {
            let snapshot = try await docRef.getDocument()
            let medicine = try snapshot.data(as: Medicine.self)
            return medicine
        } catch {
            print("Error fetching medicine: \(error)")
            return nil
        }
    }
    
    func fetchAisles(collection: String, onUpdate: @escaping ([String]) -> Void) -> ListenerRegistration {
        print("fetchAisles appelé")
        
        let listener = db.collection(collection).addSnapshotListener { (querySnapshot, error) in
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
    
    func addMedicine(collection: String, _ medicine: Medicine, user: String) async throws -> Medicine {
        print("add medicine appelé")

        let docId = medicine.id ?? UUID().uuidString
        var medicineToSave = medicine
        medicineToSave.id = docId
        medicineToSave.name_lowercase = medicine.name.lowercased()
        //let stockPadded = String(format: "%05d", medicineToSave.stock)
        //medicineToSave.combinedField = "\(medicineToSave.name_lowercase)_\(stockPadded)"
        do {
            try db.collection(collection).document(docId).setData(from: medicineToSave)

            print("✅ Medicine ajouté")

            return medicineToSave
        } catch {
            print("❌ Error adding medicine: \(error)")
            throw error
        }
    }
    
    func deleteMedicines(collection: String, withIds ids: [String]) async -> [String] {
        var deletedIds: [String] = []

        for id in ids {
            do {
                try await db.collection(collection).document(id).delete()
                print("✅ Successfully deleted medicine with id \(id)")
                deletedIds.append(id)
            } catch {
                print("❌ Error removing document \(id): \(error.localizedDescription)")
            }
        }

        return deletedIds
    }
    
    func updateStock(collection: String, for medicineId: String, newStock: Int) async throws {
            try await db.collection(collection).document(medicineId).updateData(["stock": newStock])
        }
    
    func updateMedicine(collection: String,_ medicine: Medicine) async throws {
        guard let id = medicine.id else { return }
        // 1️⃣ Crée une copie modifiable
        var medicineToUpdate = medicine
        
        // 2️⃣ Mets à jour name_lowercase
        medicineToUpdate.name_lowercase = medicine.name.lowercased()
        
        // 3️⃣ Mets à jour combinedField
        //let stockPadded = String(format: "%05d", medicineToUpdate.stock)
        //medicineToUpdate.combinedField = "\(medicineToUpdate.name_lowercase)_\(stockPadded)"
        
        try db.collection(collection).document(id).setData(from: medicineToUpdate)
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
    
    func deleteHistory(collection: String, for medicineIds: [String]) async throws {
        guard !medicineIds.isEmpty else { return }
        
        // Firestore limite à 10 valeurs max pour whereField donc on découpe le tableau
        let chunks = medicineIds.chunked(into: 10)
        
        for chunk in chunks {
            let querySnapshot = try await db.collection(collection)
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
    
    func fetchHistoryBatch(collection: String,for medicineId: String, pageSize: Int = 20, lastDocument: DocumentSnapshot? = nil, completion: @escaping ([HistoryEntry], DocumentSnapshot?) -> Void) {
        var query: Query = db.collection(collection)
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
    
    func createUser(collection: String, user: AppUser) async throws {
        let docRef = db.collection(collection).document(user.uid)
        do {
            try docRef.setData(from: user)
            print("Utilisateur créé avec succès dans firestore !")
        } catch {
            print("Erreur lors de la création de l'utilisateur : \(error)")
            throw error
        }
    }
    
    func getEmail(collection: String, uid: String) async throws -> String? {
        let docRef = db.collection(collection).document(uid)
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
