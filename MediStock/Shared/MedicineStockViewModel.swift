import Foundation
import Firebase

@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var filterText: String = ""
    var lastMedicinesDocument: DocumentSnapshotType?
    @Published var sortOption: Enumerations.SortOption = .none
    let firestoreService: FirestoreServicing
    let dataStore: DataStore
    @Published var appError: AppError?
    
    //MARK: -Initialization
    init(
        firestoreService: FirestoreServicing = FirestoreService.shared,
        dataStore: DataStore
    ) {
        self.firestoreService = firestoreService
        self.dataStore = dataStore
    }
    
    func fetchNextMedicinesBatch(pageSize: Int = 20, filterText: String? = nil) {
        firestoreService.fetchMedicinesBatch(collection: "medicines", sortOption: sortOption, filterText: filterText, pageSize: pageSize, lastDocument: lastMedicinesDocument) { [weak self] newMedicines, lastDoc, error in
            guard let self = self else { return }
            if let error = error {
                self.appError = AppError.fromFirestore(error)
                return
            }
            self.dataStore.addMedicinesToLocal(newMedicines)
            self.lastMedicinesDocument = lastDoc
            self.appError = nil
        }
    }

    func deleteMedicines(at offsets: IndexSet) async -> [String] {
        let idsToDelete = offsets.compactMap { dataStore.medicines[$0].id }

        // Supprimer côté Firestore
        do {
            let deletedIds = try await firestoreService.deleteMedicines(collection: "medicines", withIds: idsToDelete)
            // Supprimer localement avant l'appel Firestore
                   dataStore.removeMedicines(at: offsets)
            do {
                try await deleteHistory(for: deletedIds)
            } catch {
                self.appError = AppError.fromFirestore(error)
                return []
            }
            self.appError = nil
            return deletedIds
        } catch {
            self.appError = AppError.fromFirestore(error)
            return []
        }
    }

    func deleteHistory(for medicineIds: [String]) async throws {
        guard !medicineIds.isEmpty else { return }
        
        do {
            try await firestoreService.deleteHistory(collection: "history", for: medicineIds)
            dataStore.removeHistory(for: medicineIds)
            self.appError = nil
        } catch {
            throw error
        }
    }
}
