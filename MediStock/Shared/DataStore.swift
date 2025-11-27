//
//  DataShare.swift
//  MediStock
//
//  Created by Ordinateur elena on 21/11/2025.
//

import Foundation

@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()
    
    @Published var medicines: [Medicine] = []
    @Published var history: [HistoryEntry] = []
    
    init() {}
    
    func updateMedicineStock(id: String, newStock: Int) {
        if let index = medicines.firstIndex(where: { $0.id == id }) {
            medicines[index].stock = newStock
        }
    }
    
    // Met à jour un médicament complet
    func updateMedicine(_ medicine: Medicine) {
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
        }
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) {
        if !history.contains(where: { $0.id == entry.id }) {
            history.append(entry)
        }
    }
    
    // Ajoute PLUSIEURS entrées d'historique (pour le fetch paginé)
    func addHistoryEntries(_ newEntries: [HistoryEntry]) {
        for entry in newEntries {
            if !history.contains(where: { $0.id == entry.id }) {
                history.append(entry)
            }
        }
    }
    
    func addMedicinesToLocal(_ newMedicines: [Medicine]) {
            for medicine in newMedicines {
                if !medicines.contains(where: { $0.id == medicine.id }) {
                    medicines.append(medicine)
                }
            }
            print("✅ \(newMedicines.count) medicines ajoutés")
        }
        
    func removeMedicines(at offsets: IndexSet) {
            medicines.remove(atOffsets: offsets)
            print("✅ \(offsets.count) medicines supprimés localement")
        }
    
    func removeHistory(for medicineIds: [String]) {
            history.removeAll { medicineIds.contains($0.medicineId) }
            print("✅ History supprimé pour \(medicineIds.count) medicine(s)")
        }
}
