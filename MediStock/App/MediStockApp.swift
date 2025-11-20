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

    
    init() {
        FirebaseApp.configure()
        let session = SessionViewModel() // local
        _sessionVM = StateObject(wrappedValue: session)
        _loginVM = StateObject(wrappedValue: LoginViewModel(sessionVM: session))
        _aisleListVM = StateObject(wrappedValue: AisleListViewModel(sessionVM: session))
    }
    var body: some Scene {
        WindowGroup {
            ContentView(medicineStockVM: medicineStockVM, loginVM: loginVM, aisleListVM: aisleListVM)
                .environmentObject(sessionVM)
        }
    }
}

