import SwiftUI

struct MedicineListView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    var aisle: String

    var body: some View {
        List {
            ForEach(medicineStockVM.medicines.filter { $0.aisle == aisle }, id: \.id) { medicine in
                NavigationLink(destination: MedicineDetailView(medicine: medicine, medicineStockVM: medicineStockVM, isNew: false)) {
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
        .navigationBarTitle(aisle)
        .onAppear {
            medicineStockVM.fetchNextMedicinesBatch()
        }
    }
}

struct MedicineListView_Previews: PreviewProvider {
    static var previews: some View {
        MedicineListView(medicineStockVM: MedicineStockViewModel(), aisle: "Aisle 1").environmentObject(SessionViewModel())
    }
}
