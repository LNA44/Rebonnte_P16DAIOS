import Foundation
import Firebase

@MainActor
class MedicineStockViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var aisles: [String] = []
    @Published var history: [HistoryEntry] = []
    @Published var filterText: String = ""
    var lastMedicinesDocument: DocumentSnapshot?
    //private var historyListener: ListenerRegistration?
    //private var medicinesListener: ListenerRegistration?
    private var aislesListener: ListenerRegistration?
    @Published var sortOption: Enumerations.SortOption = .none
    let firestoreService: FirestoreServicing
    
    //MARK: -Initialization
    init(
        firestoreService: FirestoreServicing = FirestoreService.shared
    ) {
        self.firestoreService = firestoreService
    }
    
    func fetchNextMedicinesBatch(pageSize: Int = 20, filterText: String? = nil) {
        firestoreService.fetchMedicinesBatch(sortOption: sortOption, filterText: filterText, pageSize: pageSize, lastDocument: lastMedicinesDocument) { [weak self] newMedicines, lastDoc in
            guard let self = self else { return }
            DispatchQueue.main.async {
                for med in newMedicines {
                    if !self.medicines.contains(where: { $0.id == med.id }) {
                        self.medicines.append(med)
                    }
                }
                self.lastMedicinesDocument = lastDoc
            }
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
}
