import SwiftUI

struct MedicineListView: View {
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var medicineStockVM: MedicineStockViewModel
    var aisle: String
    @State private var isInitialLoadDone = false  // ✅ Flag
    private var filteredMedicines: [Medicine] {
            dataStore.medicines.filter { $0.aisle == aisle }
    }
    
    init(aisle: String) {
        self.aisle = aisle
        print("🏗️ INIT MedicineListView pour \(aisle)")
    }
    
    var body: some View {
        List {
            ForEach(filteredMedicines, id: \.id) { medicine in
                NavigationLink(value: medicine) {
                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                        Text("Stock: \(medicine.stock)")
                            .font(.subheadline)
                    }
                    
                }
                .onAppear {
                    if isInitialLoadDone && medicine.id == filteredMedicines.last?.id {
                        print("📄 Pagination: chargement suivant")
                        medicineStockVM.fetchNextMedicinesBatch()
                    }
                }
            }
            .onDelete { indexSet in
                Task {
                    await medicineStockVM.deleteMedicines(at: indexSet)
                    //await medicineStockVM.deleteHistory(for: medicinesId)
                }
            }
        }
        .navigationDestination(for: Medicine.self) { medicine in
            MedicineDetailView(medicine: medicine, isNew: false)
        }
        .navigationBarTitle(aisle)
        /*.onAppear {
         print("👁️ APPEAR MedicineListView - \(aisle)")
         // ✅ Charger seulement la première fois ET si vide
         if !hasAppeared && filteredMedicines.isEmpty {
         print("🔄 Premier chargement pour \(aisle)")
         medicineStockVM.fetchNextMedicinesBatch()
         hasAppeared = true
         }
         }*/
        .task { 
            guard !isInitialLoadDone else { return }
            medicineStockVM.fetchNextMedicinesBatch()
            isInitialLoadDone = true
        }
        .onDisappear {
            print("👋 DISAPPEAR MedicineListView - \(aisle)")
        }
        .alert(item: $medicineStockVM.appError) { appError in
            Alert(
                title: Text("Erreur"),
                message: Text(appError.userMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        
        let dataStore = DataStore()
        let medicineStockVM = MedicineStockViewModel(dataStore: dataStore)
        
        dataStore.medicines = [
            Medicine(name: "Doliprane", stock: 42, aisle: "A1"),
            Medicine(name: "Ibuprofen", stock: 20, aisle: "A1"),
            Medicine(name: "Vitamine C", stock: 15, aisle: "A2")
        ]
        
        return NavigationStack {
            MedicineListView(aisle: "A1")
                .environmentObject(dataStore)
                .environmentObject(medicineStockVM)
        }
    }
}
