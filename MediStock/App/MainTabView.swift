import SwiftUI

struct MainTabView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @ObservedObject var aisleListVM: AisleListViewModel

    var body: some View {
        TabView {
            AisleListView(medicineStockVM: medicineStockVM, aisleListVM: aisleListVM)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView(medicineStockVM: medicineStockVM)
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("All Medicines")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(medicineStockVM: MedicineStockViewModel(), aisleListVM: AisleListViewModel(sessionVM: SessionViewModel()))
    }
}
