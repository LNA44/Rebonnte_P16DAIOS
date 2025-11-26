import SwiftUI

struct AisleListView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject var aisleListVM: AisleListViewModel
    @State private var showNewMedicine: Bool? = nil

    init(aisleListVM: AisleListViewModel) {
            _aisleListVM = StateObject(wrappedValue: aisleListVM)
        print("🏗️ INIT AisleListView")
        }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(aisleListVM.aisles, id: \.self) { aisle in
                    NavigationLink(value: aisle) {
                        Text(aisle)
                            .accessibilityHint("Tap to view medicines in this aisle")
                    }
                }
            }
            .navigationBarTitle("Aisles")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        aisleListVM.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .imageScale(.large)     
                            .foregroundColor(.blue)
                            .accessibilityLabel("Sign out")
                            .accessibilityHint("Tap to sign out from the application")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: {
                                        showNewMedicine = true
                                    }) {
                                        Image(systemName: "plus")
                                            .accessibilityLabel("Add new medicine")
                                            .accessibilityHint("Tap to add a new medicine")
                                    }
                                }
            }
            .navigationDestination(for: String.self) { aisle in
                MedicineListView(
                    aisle: aisle
                )
            }

            .navigationDestination(item: $showNewMedicine) { _ in
                            MedicineDetailView(
                                medicine: Medicine(name: "", stock: 0, aisle: ""),
                                isNew: true
                            )
                        }
        }
        .onAppear {
            aisleListVM.fetchAisles()
        }
        .alert(item: $aisleListVM.appError) { appError in
            Alert(
                title: Text("Erreur"),
                message: Text(appError.userMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        
        let session = SessionViewModel()
        
        let aisleVM = AisleListViewModel()
        aisleVM.aisles = ["A1", "A2", "B1", "B2"]
        
        return NavigationStack {
            AisleListView(aisleListVM: AisleListViewModel())
                .environmentObject(session)
                .environmentObject(DataStore())
                .environmentObject(MedicineStockViewModel(dataStore: DataStore.shared))
                .environmentObject(aisleVM)
        }
    }
}
