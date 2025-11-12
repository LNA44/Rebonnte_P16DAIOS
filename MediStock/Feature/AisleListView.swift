import SwiftUI

struct AisleListView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(medicineStockVM.aisles, id: \.self) { aisle in
                    NavigationLink(destination: MedicineListView(medicineStockVM: medicineStockVM, aisle: aisle)) {
                        Text(aisle)
                    }
                }
            }
            .navigationBarTitle("Aisles")
            .navigationBarItems(trailing:
                    NavigationLink(destination:
                        MedicineDetailView(
                            medicine: Medicine(name: "", stock: 0, aisle: ""), medicineStockVM: medicineStockVM,
                            isNew: true
                        )
                    ) {
                Image(systemName: "plus")
            })
        }
        .onAppear {
            medicineStockVM.fetchAisles()
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView(medicineStockVM: MedicineStockViewModel())
    }
}
