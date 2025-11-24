import SwiftUI

struct MedicineListView: View {
    @EnvironmentObject var dataStore: DataStore
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @ObservedObject var medicineDetailVM: MedicineDetailViewModel
    var aisle: String

    var body: some View {
        List {
            ForEach(dataStore.medicines.filter { $0.aisle == aisle }, id: \.id) { medicine in
                NavigationLink(destination: MedicineDetailView(medicine: medicine, medicineStockVM: medicineStockVM, medicineDetailVM: medicineDetailVM, isNew: false)) {
                    VStack(alignment: .leading) {
                        Text(medicine.name)
                            .font(.headline)
                        Text("Stock: \(medicine.stock)")
                            .font(.subheadline)
                    }
                    .onAppear {
                        if medicine == dataStore.medicines.last {
                            medicineStockVM.fetchNextMedicinesBatch()
                        }
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
        .navigationBarTitle(aisle)
        .onAppear {
            medicineStockVM.fetchNextMedicinesBatch()
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

/*struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineListView(medicineStockVM: MedicineStockViewModel(), medicineDetailVM: MedicineDetailViewModel(medicineStockVM: MedicineStockViewModel()), aisle: "Aisle 1").environmentObject(SessionViewModel())
    }
}
*/
