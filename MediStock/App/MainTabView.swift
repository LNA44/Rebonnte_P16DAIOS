import SwiftUI

struct MainTabView: View {
   @EnvironmentObject var session: SessionViewModel

    var body: some View {
        TabView {
            AisleListView(aisleListVM: AisleListViewModel(sessionVM: session))
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

