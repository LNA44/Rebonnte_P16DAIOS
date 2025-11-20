//
//  MediStockApp.swift
//  MediStock
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import SwiftUI
import Firebase

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var medicineStockVM = MedicineStockViewModel()
    @StateObject var sessionVM: SessionViewModel
    @StateObject private var loginVM: LoginViewModel
    @StateObject private var aisleListVM: AisleListViewModel
    @StateObject private var medicineDetailVM: MedicineDetailViewModel
    
        init() {
            FirebaseApp.configure()
            
            let session = SessionViewModel()
            let login = LoginViewModel(sessionVM: session)
            let aisleList = AisleListViewModel(sessionVM: session)
            let stockVM = MedicineStockViewModel()
            let medicineDetail = MedicineDetailViewModel(medicineStockVM: stockVM)
            
            _sessionVM = StateObject(wrappedValue: session)
            _loginVM = StateObject(wrappedValue: login)
            _aisleListVM = StateObject(wrappedValue: aisleList)
            _medicineStockVM = StateObject(wrappedValue: stockVM)
            _medicineDetailVM = StateObject(wrappedValue: medicineDetail)
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView(medicineStockVM: medicineStockVM, loginVM: loginVM, aisleListVM: aisleListVM, medicineDetailVM: medicineDetailVM)
                .environmentObject(sessionVM)
        }
    }
}

