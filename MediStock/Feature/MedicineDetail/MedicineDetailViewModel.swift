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
    let dataStore: DataStore
    let firestoreService: FirestoreServicing
    //private weak var medicineStockVM: MedicineStockViewModel?
    var lastDocument: DocumentSnapshot? //history document
    @Published var emailsCache: [String: String] = [:] // uid -> email
    @Published var appError: AppError?
    
    //MARK: -Initialization
    init(
        authService: AuthServicing = AuthService.shared,
        firestoreService: FirestoreServicing = FirestoreService.shared,
        dataStore: DataStore
        //medicineStockVM: MedicineStockViewModel
    ) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.dataStore = dataStore
       // self.medicineStockVM = medicineStockVM
    }
 
    func addMedicine(_ medicine: Medicine, user: String) async -> Medicine {
        print("add medicine appelé dans la ViewModel")

        do {
            // Appel du service
            let savedMedicine = try await firestoreService.addMedicine(collection: "medicines", medicine, user: user)

            // Appel asynchrone de addHistory
                _ = await addHistory(
                    action: "Medicine created",
                    user: user,
                    medicineId: savedMedicine.id ?? "",
                    details: ""
                )
            self.appError = nil
            return savedMedicine
        } catch {
            self.appError = AppError.fromFirestore(error)
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
    //OK
    func updateStock(_ medicine: Medicine, by amount: Int, user: String) async -> Int {
        print("updateStock appelé")
        guard let id = medicine.id else { return 0 }
        
        let currentStock = dataStore.medicines.first(where: { $0.id == id })?.stock ?? medicine.stock
        let newStock = currentStock + amount
        
        do {
            // 1️⃣ Mise à jour dans Firestore via le service
            try await firestoreService.updateStock(collection: "medicines", for: id, newStock: newStock)
            
            // 2️⃣ Mise à jour locale
            dataStore.updateMedicineStock(id: id, newStock: newStock)
            
            // 3️⃣ Ajout à l'historique
            _ = await addHistory(
                action: "\(amount > 0 ? "Increased" : "Decreased") stock of \(medicine.name) by \(amount)",
                user: user,
                medicineId: id,
                details: "Stock changed from \(currentStock) to \(newStock)"
            )
            self.appError = nil
            return newStock
        } catch {
            self.appError = AppError.fromFirestore(error)
            return currentStock
        }
    }
    //OK
    func updateMedicine(_ medicine: Medicine, user: String, shouldAddHistory: Bool = true) async {
        print("update medicine appelé")
        guard let id = medicine.id else { return }
        
        do {
            // 1️⃣ Mise à jour Firestore
            try await firestoreService.updateMedicine(collection: "medicines", medicine)
            
            // 2️⃣ Mise à jour locale
            dataStore.updateMedicine(medicine)
            
            // 3️⃣ Ajout à l'historique si demandé
            if shouldAddHistory {
                _ = await addHistory(
                    action: "Updated \(medicine.name)",
                    user: user,
                    medicineId: id,
                    details: "Updated medicine details"
                )
            }
            self.appError = nil
        } catch {
            self.appError = AppError.fromFirestore(error)
        }
    }
    
    func addHistory(action: String,user: String,medicineId: String,details: String) async -> HistoryEntry? {
        print("addHistory appelé dans la ViewModel")
       // guard let stockVM = medicineStockVM else { return nil }

        do {
            // Appel du service
            let historyEntry = try await firestoreService.addHistory(
                action: action,
                user: user,
                medicineId: medicineId,
                details: details
            )
            
            if let historyEntry = historyEntry {
                print("✅ History créé pour medicine \(medicineId)")
                
                // Mise à jour locale de l'historique
                dataStore.addHistoryEntry(historyEntry)
            }
            self.appError = nil
            return historyEntry
        } catch {
            self.appError = AppError.fromFirestore(error)
            return nil
        }
    }
    
    func fetchNextHistoryBatch(for medicine: Medicine, pageSize: Int = 20) {
        guard let medicineId = medicine.id else { return }

        firestoreService.fetchHistoryBatch(collection: "history", for: medicineId, pageSize: pageSize, lastDocument: lastDocument) { [weak self] newEntries, lastDoc, error in
            guard let self = self else { return }
            if let error = error {
                self.appError = AppError.fromFirestore(error)
                return
            }
            self.dataStore.addHistoryEntries(newEntries)
            
            self.lastDocument = lastDoc
            self.appError = nil
        }
    }
    
    func fetchEmail(for uid: String) async -> String {
        if let cached = emailsCache[uid] {
            return cached
        }
        do {
            let email = try await firestoreService.getEmail(collection: "users", uid: uid) ?? "Unknown"
            emailsCache[uid] = email
            self.appError = nil
            return email
        } catch {
            emailsCache[uid] = "Error"
            self.appError = AppError.fromFirestore(error)
            return "Error"
        }
    }
}
