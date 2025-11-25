import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionViewModel
   /* @ObservedObject var loginVM: LoginViewModel
    @ObservedObject var aisleListVM: AisleListViewModel
    @ObservedObject var medicineDetailVM: MedicineDetailViewModel*/

    var body: some View {
        Group {
            if session.session != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            session.listen()
        }
    }
}

/*struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(medicineStockVM: MedicineStockViewModel(), loginVM: LoginViewModel(sessionVM: SessionViewModel()), aisleListVM: AisleListViewModel(sessionVM: SessionViewModel()), medicineDetailVM: MedicineDetailViewModel(medicineStockVM: MedicineStockViewModel())).environmentObject(SessionViewModel())
    }
}
*/
