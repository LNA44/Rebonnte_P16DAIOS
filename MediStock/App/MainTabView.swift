import SwiftUI

struct MainTabView: View {
    /*@ObservedObject var aisleListVM: AisleListViewModel
    @ObservedObject var medicineDetailVM: MedicineDetailViewModel*/

    var body: some View {
        TabView {
            AisleListView()
                .tabItem {
                    Image(systemName: "list.dash")
                    Text("Aisles")
                }

            AllMedicinesView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("All Medicines")
                }
        }
    }
}

