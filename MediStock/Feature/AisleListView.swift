import SwiftUI

struct AisleListView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(medicineStockVM.aisles, id: \.self) { aisle in
                    NavigationLink(destination: MedicineListView(medicineStockVM: medicineStockVM, aisle: aisle)) {
                        Text(aisle)
                    }
                }
            }
            .navigationBarTitle("Aisles")
            .navigationBarItems(trailing: Button(action: {
                medicineStockVM.addRandomMedicine(user: "test_user") // Remplacez par l'utilisateur actuel
            }) {
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
