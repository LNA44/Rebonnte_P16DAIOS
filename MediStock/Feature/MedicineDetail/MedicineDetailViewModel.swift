//
//  MedicineDetailViewModel.swift
//  MediStock
//
//  Created by Ordinateur elena on 20/11/2025.
//

import Foundation
import Firebase
@MainActor
class MedicineDetailViewModel: ObservableObject {
    let authService: AuthServicing
    let firestoreService: FirestoreServicing
    private let medicineStockVM: MedicineStockViewModel
    var lastDocument: DocumentSnapshot? //history document
    @Published var emailsCache: [String: String] = [:] // uid -> email
    
    //MARK: -Initialization
    init(
        authService: AuthServicing = AuthService.shared,
        firestoreService: FirestoreServicing = FirestoreService.shared,
        medicineStockVM: MedicineStockViewModel
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.medicineStockVM = medicineStockVM
    }
 
    func addMedicine(_ medicine: Medicine, user: String) async -> Medicine {
        print("add medicine appelé dans la ViewModel")

        do {
            // Appel du service
            let savedMedicine = try await firestoreService.addMedicine(collection: "medicines", medicine, user: user)

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

            return savedMedicine
        } catch {
            print("❌ Error adding medicine dans la ViewModel: \(error)")
            return Medicine(name: "", stock: 0, aisle: "")
        }
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

        let currentStock = medicineStockVM.medicines.first(where: { $0.id == id })?.stock ?? medicine.stock
            let newStock = currentStock + amount

            do {
                // 1️⃣ Mise à jour dans Firestore via le service
                try await firestoreService.updateStock(collection: "medicines", for: id, newStock: newStock)

                // 2️⃣ Mise à jour locale
                if let index = medicineStockVM.medicines.firstIndex(where: { $0.id == id }) {
                    medicineStockVM.medicines[index].stock = newStock
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
                try await firestoreService.updateMedicine(collection: "medicines", medicine)

                // 2️⃣ Mise à jour locale
                if let index = medicineStockVM.medicines.firstIndex(where: { $0.id == id }) {
                    medicineStockVM.medicines[index] = medicine
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
                    medicineStockVM.history.append(historyEntry!)
                    print("✅ History mis à jour localement: \(medicineStockVM.history.count) entrées")
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
    
    func fetchNextHistoryBatch(for medicine: Medicine, pageSize: Int = 20) {
        guard let medicineId = medicine.id else { return }
        
        firestoreService.fetchHistoryBatch(collection: "history", for: medicineId, pageSize: pageSize, lastDocument: lastDocument) { [weak self] newEntries, lastDoc in
            guard let self = self else { return }
            DispatchQueue.main.async { [self] in
                for entry in newEntries {
                    if !self.medicineStockVM.history.contains(where: { $0.id == entry.id }) {
                        self.medicineStockVM.history.append(entry)
                    }
                }
                self.lastDocument = lastDoc
            }
        }
    }
    
    func fetchEmail(for uid: String) async -> String {
        if let cached = emailsCache[uid] {
            return cached
        }
        do {
            let email = try await firestoreService.getEmail(collection: "users", uid: uid) ?? "Unknown"
            emailsCache[uid] = email
            return email
        } catch {
            emailsCache[uid] = "Error"
            return "Error"
        }
    }
}
