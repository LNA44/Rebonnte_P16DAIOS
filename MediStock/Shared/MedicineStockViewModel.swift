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
            setupNotifications()
        }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(userDidSignOut), name: .userDidSignOut, object: nil)
    }
    
    @objc private func userDidSignOut() { //arrete les listeners avt destruction du VM pour eviter erreurs firebase qui manque de permissions
        medicinesListener?.remove()
        medicinesListener = nil
        
        aislesListener?.remove()
        aislesListener = nil
        
        historyListener?.remove()
        historyListener = nil
        
        print("🔕 Tous les listeners arrêtés suite à la déconnexion")
    }

    
    func fetchMedicines() {
        print("fetchMedicines VM appelé")
        
        // Supprimer l'ancien listener si existant
        medicinesListener?.remove()
        
        medicinesListener = firestoreService.fetchMedicines(sortOption: sortOption, filterText: filterText) { [weak self] fetchedMedicines in
            self?.medicines = fetchedMedicines
        }
    }
    
    func fetchMedicine(by id: String) async -> Medicine? {
        return await firestoreService.fetchMedicine(id)
    }

    func fetchAisles() {
        // Retirer l'ancien listener si existant
        aislesListener?.remove()
        
        aislesListener = firestoreService.fetchAisles { [weak self] aisles in
            self?.aisles = aisles
        }
    }

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

    func deleteHistory(for medicineIds: [String]) async {
        guard !medicineIds.isEmpty else { return }
        
        do {
            // Appel au service
            try await firestoreService.deleteHistory(for: medicineIds)
            
            // Mise à jour du state local
            await MainActor.run {
                self.history.removeAll { medicineIds.contains($0.medicineId) }
                print("✅ Historique local mis à jour : \(medicineIds.count) médicament(s)")
            }
            
        } catch {
            await MainActor.run {
                //self.errorMessage = "Erreur lors de la suppression de l'historique : \(error.localizedDescription)"
                //self.showError = true
            }
            print("❌ Erreur deleteHistory : \(error.localizedDescription)")
        }
    }

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
                    let confirmedDocs = querySnapshot.documents
                        .compactMap { try? $0.data(as: HistoryEntry.self) }
                    
                    DispatchQueue.main.async {
                        self.history = confirmedDocs
                    }
                }
            }
    }
    
    deinit {
        // ✅ Retire tous les listeners a la suppression du VM
        NotificationCenter.default.removeObserver(self)
        medicinesListener?.remove()
        historyListener?.remove()
        aislesListener?.remove()
        
        print("🧹 Tous les listeners nettoyés")
    }
}
