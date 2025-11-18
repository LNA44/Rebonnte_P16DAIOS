import SwiftUI

struct MainTabView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AisleListView(medicineStockVM: medicineStockVM, selectedTab: $selectedTab)
                .tag(0)
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView(medicineStockVM: medicineStockVM)
                .tag(1)
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
