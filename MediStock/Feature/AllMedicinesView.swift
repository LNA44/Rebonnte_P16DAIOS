import SwiftUI

struct AllMedicinesView: View {
    @EnvironmentObject var session: SessionViewModel
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @State private var sortOption: Enumerations.SortOption = .none
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtrage et Tri
                HStack {
                    TextField("Filter by name", text: $medicineStockVM.filterText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)
                        .onChange(of: medicineStockVM.filterText) { _, newValue in
                            medicineStockVM.fetchNextMedicinesBatch()
                        }
                    
                    Spacer()
                    
                    Picker("Sort by", selection: $sortOption) {
                        Text("None").tag(Enumerations.SortOption.none)
                        Text("Name").tag(Enumerations.SortOption.name)
                        Text("Stock").tag(Enumerations.SortOption.stock)
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(.trailing, 10)
                }
                .padding(.top, 10)
                
                // Liste des Médicaments
                List {
                    ForEach(medicineStockVM.medicines, id: \.id) { medicine in
                        NavigationLink(destination: MedicineDetailView(medicine: medicine, medicineStockVM: medicineStockVM)) {
                            VStack(alignment: .leading) {
                                Text(medicine.name)
                                    .font(.headline)
                                Text("Stock: \(medicine.stock)")
                                    .font(.subheadline)
                            }
                            .onAppear {
                                if medicine == medicineStockVM.medicines.last {
                                    medicineStockVM.fetchNextMedicinesBatch()
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                        let medicinesId = await medicineStockVM.deleteMedicines(at: indexSet)
                    
                            await medicineStockVM.deleteHistory(for: medicinesId)
                        }
                    }
                }
                .navigationBarTitle("All Medicines")
                .navigationBarItems(trailing: NavigationLink(destination:
                    MedicineDetailView(
                        medicine: Medicine(name: "", stock: 0, aisle: ""), medicineStockVM: medicineStockVM,
                        isNew: true
                    )
                                                            ) {
                    Image(systemName: "plus")
                })
            }
        }
        .onAppear {
            medicineStockVM.fetchNextMedicinesBatch()
        }
    }
}

struct AllMedicinesView_Previews: PreviewProvider {
    static var previews: some View {
        AllMedicinesView(medicineStockVM: MedicineStockViewModel())
    }
}
