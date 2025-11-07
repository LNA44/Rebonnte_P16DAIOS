import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject var medicineStockVM = MedicineStockViewModel()

    var body: some View {
        Group {
            if session.session != nil {
                MainTabView(medicineStockVM: medicineStockVM)
            } else {
                LoginView()
            }
        }
        .onAppear {
            session.listen()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionViewModel())
    }
}
