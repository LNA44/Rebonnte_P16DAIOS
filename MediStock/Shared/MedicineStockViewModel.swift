import Foundation
import Firebase

@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    @Published var filterText: String = ""
    var lastMedicinesDocument: DocumentSnapshot?
    private var aislesListener: ListenerRegistration?
    @Published var sortOption: Enumerations.SortOption = .none
    let firestoreService: FirestoreServicing
    @Published var appError: AppError?
    
    //MARK: -Initialization
    init(
        firestoreService: FirestoreServicing = FirestoreService.shared
    ) {
        self.firestoreService = firestoreService
    }
    
    func fetchNextMedicinesBatch(pageSize: Int = 20, filterText: String? = nil) {
        firestoreService.fetchMedicinesBatch(collection: "medicines", sortOption: sortOption, filterText: filterText, pageSize: pageSize, lastDocument: lastMedicinesDocument) { [weak self] newMedicines, lastDoc, error in
            guard let self = self else { return }
            if let error = error {
                self.appError = AppError.fromFirestore(error)
            }
            for med in newMedicines {
                if !self.medicines.contains(where: { $0.id == med.id }) {
                    self.medicines.append(med)
                }
            }
            self.lastMedicinesDocument = lastDoc
            self.appError = nil
        }
    }

    func deleteMedicines(at offsets: IndexSet) async -> [String] {
        let idsToDelete = offsets.compactMap { medicines[$0].id }

        // Supprimer localement avant l'appel Firestore
        medicines.remove(atOffsets: offsets)
        // Supprimer côté Firestore
        do {
            let deletedIds = try await firestoreService.deleteMedicines(collection: "medicines", withIds: idsToDelete)
            self.appError = nil
            return deletedIds
        } catch {
            self.appError = AppError.fromFirestore(error)
            return []
        }
    }

    func deleteHistory(for medicineIds: [String]) async {
        guard !medicineIds.isEmpty else { return }
        
        do {
            // Appel au service
            try await firestoreService.deleteHistory(collection: "history", for: medicineIds)
            
            // Mise à jour du state local
            self.history.removeAll { medicineIds.contains($0.medicineId) }
            self.appError = nil
            print("✅ Historique local mis à jour : \(medicineIds.count) médicament(s)")
        } catch {
            self.appError = AppError.fromFirestore(error)
        }
    }
}
