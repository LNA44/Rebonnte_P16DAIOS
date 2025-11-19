import SwiftUI

struct MainTabView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    
    var body: some View {
        TabView {
            AisleListView(medicineStockVM: medicineStockVM)
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
        MainTabView(medicineStockVM: MedicineStockViewModel())
    }
}
