import SwiftUI

struct AisleListView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @EnvironmentObject var session: SessionViewModel
    @ObservedObject var aisleListVM: AisleListViewModel
    @ObservedObject var medicineDetailVM: MedicineDetailViewModel
    @State private var showNewMedicine = false

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
                    medicineStockVM: medicineStockVM,
                    medicineDetailVM: medicineDetailVM,
                    aisle: aisle
                )
            }
            .navigationDestination(isPresented: $showNewMedicine) {
                MedicineDetailView(
                    medicine: Medicine(name: "", stock: 0, aisle: ""),
                    medicineStockVM: medicineStockVM,
                    medicineDetailVM: medicineDetailVM,
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

/*struct AisleListView_Previews: PreviewProvider {
    static var previews: some View {
        AisleListView(medicineStockVM: MedicineStockViewModel(), aisleListVM: AisleListViewModel(sessionVM: SessionViewModel()), medicineDetailVM: MedicineDetailViewModel(medicineStockVM: MedicineStockViewModel()))
    }
}
*/
