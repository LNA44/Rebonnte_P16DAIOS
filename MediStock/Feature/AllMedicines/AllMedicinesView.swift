import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var session: SessionViewModel
    @EnvironmentObject var dataStore: DataStore
    @EnvironmentObject var medicineStockVM: MedicineStockViewModel
    @State private var showNewMedicine: Bool? = nil
    
    var body: some View {
        NavigationStack {
                VStack {
                    // Filtrage et Tri
                    HStack {
                        TextField("Filter by name", text: $medicineStockVM.filterText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading, 10)
                            .accessibilityLabel("Filter by name")
                            .accessibilityHint("Enter text to filter the list of medicines by name")
                            .onChange(of: medicineStockVM.filterText) { _, newValue in
                                let lowerFilter = newValue.lowercased()
                                dataStore.medicines = []
                                medicineStockVM.lastMedicinesDocument = nil
                                medicineStockVM.fetchNextMedicinesBatch(filterText: lowerFilter.isEmpty ? nil : lowerFilter)
                            }
                        
                        Spacer()
                        
                        Picker("Sort by", selection: $medicineStockVM.sortOption) {
                            Text("None").tag(Enumerations.SortOption.none)
                            Text("Name").tag(Enumerations.SortOption.name)
                            Text("Stock").tag(Enumerations.SortOption.stock)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.trailing, 10)
                        .accessibilityLabel("Sort options")
                        .accessibilityHint("Select how to sort the list of medicines")
                        .onChange(of: medicineStockVM.sortOption) {_, newSort in
                            // Réinitialiser la pagination et la liste
                            dataStore.medicines = []
                            medicineStockVM.lastMedicinesDocument = nil
                            // Recharger les medicines triées
                            medicineStockVM.fetchNextMedicinesBatch(filterText: medicineStockVM.filterText.isEmpty ? nil : medicineStockVM.filterText)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Liste des Médicaments
                    List {
                        ForEach(dataStore.medicines, id: \.id) { medicine in
                            NavigationLink(value: medicine) {
                                VStack(alignment: .leading) {
                                    Text(medicine.name)
                                        .font(.headline)
                                        .accessibilityLabel("Medicine name")
                                        .accessibilityValue(medicine.name)
                                    Text("Stock: \(medicine.stock)")
                                        .font(.subheadline)
                                        .accessibilityLabel("Stock quantity")
                                        .accessibilityValue("\(medicine.stock)")
                                }
                                .onAppear {
                                    if medicine == dataStore.medicines.last && medicineStockVM.filterText.isEmpty {
                                        medicineStockVM.fetchNextMedicinesBatch()
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                await medicineStockVM.deleteMedicines(at: indexSet)
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.immediately) 
                    .navigationBarTitle("All Medicines")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            // ✅ Button au lieu de NavigationLink
                            Button(action: {
                                showNewMedicine = true
                            }) {
                                Image(systemName: "plus")
                                    .accessibilityLabel("Add new medicine")
                                    .accessibilityHint("Tap to add a new medicine")
                            }
                        }
                    }
                }
                .navigationDestination(for: Medicine.self) { medicine in
                    MedicineDetailView(medicine: medicine, isNew: false)
                }
                .navigationDestination(item: $showNewMedicine) { _ in
                    MedicineDetailView(
                        medicine: Medicine(name: "", stock: 0, aisle: ""),
                        isNew: true
                    )
                }
        }
        .onAppear {
            if dataStore.medicines.isEmpty && medicineStockVM.filterText.isEmpty {
                medicineStockVM.fetchNextMedicinesBatch()
            }
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

struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        let session = SessionViewModel()
        let dataStore = DataStore()
        let medicineStockVM = MedicineStockViewModel(dataStore: dataStore)
  
        dataStore.medicines = [
            Medicine(name: "Doliprane", stock: 42, aisle: "A1"),
            Medicine(name: "Ibuprofen", stock: 20, aisle: "B3")
        ]

        return AllMedicinesView()
            .environmentObject(session)
            .environmentObject(dataStore)
            .environmentObject(medicineStockVM)
    }
}

