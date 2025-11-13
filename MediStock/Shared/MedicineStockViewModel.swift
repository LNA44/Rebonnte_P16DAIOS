import Foundation
import Firebase

@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    @Published var filterText: String = ""
    private var db = Firestore.firestore()
    private var historyListener: ListenerRegistration?
    private var medicinesListener: ListenerRegistration?
    private var aislesListener: ListenerRegistration?
    @Published private var sortOption: Enumerations.SortOption = .none
    let firestoreService: FirestoreServicing
        
        //MARK: -Initialization
        init(
            firestoreService: FirestoreServicing = FirestoreService.shared,
        ) {
            self.firestoreService = firestoreService
        }
    
    /*func fetchMedicines() {
        print("fetch medicine appelé")
        
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
        
        query.addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let fetchedMedicines = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: Medicine.self)
                    } ?? []
                    DispatchQueue.main.async {
                        self.medicines = fetchedMedicines
                    }
                }
            }
        }
    }*/
    //OK
    func fetchMedicines() {
        print("fetchMedicines VM appelé")
        
        // Supprimer l'ancien listener si existant
        medicinesListener?.remove()
        
        medicinesListener = firestoreService.fetchMedicines(sortOption: sortOption, filterText: filterText) { [weak self] fetchedMedicines in
            self?.medicines = fetchedMedicines
        }
    }
    
    /*func fetchMedicine(_ id: String) async -> Medicine? {
        let docRef = db.collection("medicines").document(id)
        
        do {
            let snapshot = try await docRef.getDocument()
            let medicine = try snapshot.data(as: Medicine.self)
            return medicine
        } catch {
            print("Error fetching medicine: \(error)")
            return nil
        }
    }*/
    //OK
    func fetchMedicine(by id: String) async -> Medicine? {
        return await firestoreService.fetchMedicine(id)
    }

    /*func fetchAisles() {
        print("fetchAisles appelé")
        db.collection("medicines").addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let allMedicines = querySnapshot?.documents.compactMap { document in
                        try? document.data(as: Medicine.self)
                    } ?? []
                    let aislesSet = Set(allMedicines.map{ $0.aisle })
                    let aislesSorted = Array(aislesSet).sorted()
                    DispatchQueue.main.async {
                        self.aisles = aislesSorted
                    }
                }
            }
        }
    }*/
    //OK
    func fetchAisles() {
        // Retirer l'ancien listener si existant
        aislesListener?.remove()
        
        aislesListener = firestoreService.fetchAisles { [weak self] aisles in
            self?.aisles = aisles
        }
    }

    /*func addMedicine(_ medicine: Medicine, user: String, completion: @escaping (Medicine) -> Void) {
        print("add medicine appelé")
        //on vérifie que l'id existe
        let docId = medicine.id ?? UUID().uuidString
        var medicineToSave = medicine
        medicineToSave.id = docId
        
        do {
            try db.collection("medicines").document(docId).setData(from: medicineToSave) { error in
                if let error = error {
                    print("Error adding document: \(error)")
                } else {
                    self.addHistory(
                        action: "Medicine created",
                        user: user,
                        medicineId: docId,
                        details: ""
                    )
                    DispatchQueue.main.async {
                        completion(medicineToSave)
                    }
                }
            }
        } catch {
            print("Error adding document: \(error)")
        }
    }*/
    //OK
    func addMedicine(_ medicine: Medicine, user: String) async -> Medicine {
        print("add medicine appelé dans la ViewModel")

        do {
            // Appel du service
            let savedMedicine = try await firestoreService.addMedicine(medicine, user: user)

            // Appel asynchrone de addHistory
                let historyEntry = await addHistory(
                    action: "Medicine created",
                    user: user,
                    medicineId: savedMedicine.id ?? "",
                    details: ""
                )

                if historyEntry != nil {
                    print("✅ History créé pour medicine \(savedMedicine.id ?? "")")
                }

                // Mise à jour locale de l'historique
                /*await MainActor.run {
                    self.history.append(historyEntry ?? HistoryEntry(
                        id: UUID().uuidString,
                        medicineId: savedMedicine.id ?? "",
                        user: user,
                        action: "Medicine created",
                        details: ""
                    ))
                    print("✅ History mis à jour localement: \(self.history.count) entrées")
                }*/
            return savedMedicine
        } catch {
            print("❌ Error adding medicine dans la ViewModel: \(error)")
            return Medicine(name: "", stock: 0, aisle: "")
        }
    }
    
    /*func deleteMedicines(at offsets: IndexSet) -> [String] {
        var deletedIds: [String] = []
        
        offsets.map { medicines[$0] }.forEach { medicine in
            if let id = medicine.id {
                deletedIds.append(id)
                db.collection("medicines").document(id).delete { error in
                    if let error = error {
                        print("Error removing document: \(error)")
                    }
                }
            }
        }
        return deletedIds
    }*/
//OK
    func deleteMedicines(at offsets: IndexSet) async -> [String] {
        let idsToDelete = offsets.compactMap { medicines[$0].id }

        // Supprimer localement avant l'appel Firestore
        medicines.remove(atOffsets: offsets)

        // Supprimer côté Firestore
        let deletedIds = await firestoreService.deleteMedicines(withIds: idsToDelete)

        return deletedIds
    }

    func increaseStock(_ medicine: Medicine, user: String) async -> Int {
        print("increaseStock appelé")
        let newStock = await updateStock(medicine, by: 1, user: user)
        return newStock
    }

    func decreaseStock(_ medicine: Medicine, user: String) async -> Int {
        print("decreaseStock appelé")
        let newStock = await updateStock(medicine, by: -1, user: user)
        return newStock
    }

    /*func updateStock(_ medicine: Medicine, by amount: Int, user: String) async -> Int {
        print("updateStock appelé")
        guard let id = medicine.id else { return 0 }

        let currentStock = self.medicines.first(where: { $0.id == id })?.stock ?? medicine.stock
        let newStock = currentStock + amount

        do {
            // 1. Mise à jour dans Firestore
            try await db.collection("medicines").document(id).updateData(["stock": newStock])

            // 2. Mise à jour locale (sur le main thread)
            await MainActor.run {
                if let index = self.medicines.firstIndex(where: { $0.id == id }) {
                    self.medicines[index].stock = newStock
                }
            }

            // 3. Ajout à l'historique (exécuté en parallèle)
            _ = await addHistory(
                action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)",
                user: user,
                medicineId: id,
                details: "Stock changed from \(currentStock) to \(newStock)"
            )

            return newStock
        } catch {
            print("Error updating stock: \(error)")
            return currentStock
        }
    }*/
    
    func updateStock(_ medicine: Medicine, by amount: Int, user: String) async -> Int {
            print("updateStock appelé")
            guard let id = medicine.id else { return 0 }

            let currentStock = medicines.first(where: { $0.id == id })?.stock ?? medicine.stock
            let newStock = currentStock + amount

            do {
                // 1️⃣ Mise à jour dans Firestore via le service
                try await firestoreService.updateStock(for: id, newStock: newStock)

                // 2️⃣ Mise à jour locale
                if let index = medicines.firstIndex(where: { $0.id == id }) {
                    medicines[index].stock = newStock
                }

                // 3️⃣ Ajout à l'historique
                _ = await addHistory(
                    action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)",
                    user: user,
                    medicineId: id,
                    details: "Stock changed from \(currentStock) to \(newStock)"
                )

                return newStock
            } catch {
                print("❌ Error updating stock: \(error)")
                return currentStock
            }
        }


    /*func updateMedicine(_ medicine: Medicine, user: String, shouldAddHistory: Bool = true) {
        print("update medicine appelé")
        guard let id = medicine.id else { return }
        do {
            try db.collection("medicines").document(id).setData(from: medicine) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else if shouldAddHistory {
                    Task {
                        await self.addHistory(action: "Updated \(medicine.name)", user: user, medicineId: id, details: "Updated medicine details")
                    }
                }
            }
        } catch let error {
            print("Error updating document: \(error)")
        }
    }*/
    
    func updateMedicine(_ medicine: Medicine, user: String, shouldAddHistory: Bool = true) async {
            print("update medicine appelé")
            guard let id = medicine.id else { return }

            do {
                // 1️⃣ Mise à jour Firestore
                try await firestoreService.updateMedicine(medicine)

                // 2️⃣ Mise à jour locale
                if let index = medicines.firstIndex(where: { $0.id == id }) {
                    medicines[index] = medicine
                }

                // 3️⃣ Ajout à l'historique si demandé
                if shouldAddHistory {
                    _ = await addHistory(
                        action: "Updated \(medicine.name)",
                        user: user,
                        medicineId: id,
                        details: "Updated medicine details"
                    )
                }

            } catch {
                print("❌ Error updating medicine: \(error)")
            }
        }

    /*func addHistory(action: String, user: String, medicineId: String, details: String) {
        print("history before adding new one: \(self.history)")
        let newId = UUID().uuidString
        let history = HistoryEntry(id: newId, medicineId: medicineId, user: user, action: action, details: details)
        do {
            print("💾 [addHistory] Envoi vers Firestore...")
            try db.collection("history").document(newId).setData(from: history) { error in
                if let error = error {
                    print("Error adding history: \(error)")
                } else {
                    self.history = self.history + [history]
                    print("history after adding a new one \(self.history)")
                }
            }
        } catch let error {
            print("Error adding history: \(error)")
        }
    }*/
    
    func addHistory(action: String,user: String,medicineId: String,details: String) async -> HistoryEntry? {
        print("addHistory appelé dans la ViewModel")

        do {
            // Appel du service
            let historyEntry = try await firestoreService.addHistory(
                action: action,
                user: user,
                medicineId: medicineId,
                details: details
            )

            if historyEntry != nil {
                print("✅ History créé pour medicine \(medicineId)")

                // Mise à jour locale de l'historique
                await MainActor.run {
                    self.history.append(historyEntry!)
                    print("✅ History mis à jour localement: \(self.history.count) entrées")
                }
            }

            return historyEntry
        } catch {
            print("❌ Error adding history dans la ViewModel: \(error)")

            // Création d'une entrée d'historique locale en cas d'échec
            let localHistoryEntry = HistoryEntry(
                id: UUID().uuidString,
                medicineId: medicineId,
                user: user,
                action: action,
                details: details
            )
            return localHistoryEntry
        }
    }
//    ---------A FAIRE--------------
    func deleteHistory(medicinesId: [String]) async {
        guard !medicinesId.isEmpty else { return }
        
        do {
            // Firestore limite à 10 valeurs max pour wherefield donc on decoupe le tableau en sous tableaux de 10 éléments
            let chunks = medicinesId.chunked(into: 10)
            
            for chunk in chunks {
                let querySnapshot = try await db.collection("history")
                    .whereField("medicineId", in: chunk)
                    .getDocuments()
                
                for document in querySnapshot.documents {
                    try await db.collection("history").document(document.documentID).delete()
                }
                
                // Mise à jour du tableau local
                await MainActor.run {
                    self.history.removeAll { chunk.contains($0.medicineId) }
                }
            }
            
            print("✅ Historique supprimé pour les médicaments : \(medicinesId)")
            
        } catch {
            print("❌ Erreur lors de la suppression de l’historique : \(error.localizedDescription)")
        }
    }

    /*func fetchHistory(for medicine: Medicine) {
        print("fetchHistory appelé")
        historyListener?.remove() //suppr l'ancien listener avant d'en créer un nouveau
        guard let medicineId = medicine.id else { return }
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener(includeMetadataChanges: false) { [weak self] (querySnapshot, error) in //includemetadatachanges -> ignore les modifs des métadonnées sinon listener maj quand cache maj
            //listener permet d'écouter les modifs de history
            guard let self = self else { return }
            if let error = error {
                print("Error getting history: \(error)")
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    // ✅ Filtrer les documents confirmés uniquement
                    let fetchedHistory = querySnapshot?.documents
                        .filter { !$0.metadata.hasPendingWrites }  // ← Ignorer les écritures locales
                        .compactMap { document in
                            try? document.data(as: HistoryEntry.self)
                        } ?? []
                    
                    print("📦 Entrées confirmées: \(fetchedHistory.count)")
                    
                    DispatchQueue.main.async {
                        self.history = fetchedHistory
                    }
                }
            }
        }
    }*/
    func fetchHistory(for medicine: Medicine) {
        historyListener?.remove()
        guard let medicineId = medicine.id else { return }
        
        historyListener = db.collection("history")
            .whereField("medicineId", isEqualTo: medicineId)
            .order(by: "timestamp", descending: true) //index créé dans firestore pour synchroniser cache et serveur ensuite
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Error: \(error)")
                    return
                }
                
                guard let querySnapshot = querySnapshot else { return }
                
                DispatchQueue.global(qos: .userInitiated).async {
                    /*let allDocs = querySnapshot.documents.compactMap {
                        try? $0.data(as: HistoryEntry.self)
                    }*/
                    
                    let confirmedDocs = querySnapshot.documents
                        .filter { !$0.metadata.hasPendingWrites }
                        .compactMap { try? $0.data(as: HistoryEntry.self) }
                    
                    DispatchQueue.main.async {
                        self.history = confirmedDocs
                    }
                }
            }
    }
    
    deinit {
        // ✅ Retire tous les listeners
        medicinesListener?.remove()
        historyListener?.remove()
        aislesListener?.remove()
        
        print("🧹 Tous les listeners nettoyés")
    }
}
