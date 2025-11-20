import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionViewModel
    @ObservedObject var medicineStockVM: MedicineStockViewModel
    @ObservedObject var loginVM: LoginViewModel
    @ObservedObject var aisleListVM: AisleListViewModel
    @ObservedObject var medicineDetailVM: MedicineDetailViewModel

    var body: some View {
        Group {
            if session.session != nil {
                MainTabView(medicineStockVM: medicineStockVM, aisleListVM: aisleListVM, medicineDetailVM: medicineDetailVM)
            } else {
                LoginView(loginVM: loginVM)
            }
        }
        .onAppear {
            session.listen()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(medicineStockVM: MedicineStockViewModel(), loginVM: LoginViewModel(sessionVM: SessionViewModel()), aisleListVM: AisleListViewModel(sessionVM: SessionViewModel()), medicineDetailVM: MedicineDetailViewModel(medicineStockVM: MedicineStockViewModel())).environmentObject(SessionViewModel())
    }
}
