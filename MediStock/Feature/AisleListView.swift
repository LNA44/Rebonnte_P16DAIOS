import SwiftUI

struct AisleListView: View {
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(medicineStockVM.aisles, id: \.self) { aisle in
                    NavigationLink(destination: MedicineListView(medicineStockVM: medicineStockVM, aisle: aisle)) {
                        Text(aisle)
                          .accessibilityHint("Tap to view medicines in this aisle")
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
                    .accessibilityLabel("Add new medicine")
                    .accessibilityHint("Tap to add a new medicine")
            })
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        session.signOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .imageScale(.large)     
                            .foregroundColor(.blue)
                            .accessibilityLabel("Sign out")
                            .accessibilityHint("Tap to sign out from the application")
                    }
                }
            }
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
