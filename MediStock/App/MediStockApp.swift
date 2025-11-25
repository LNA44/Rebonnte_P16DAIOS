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
        
    @StateObject var sessionVM = SessionViewModel.shared
       // @StateObject private var loginVM: LoginViewModel
       // @StateObject private var aisleListVM: AisleListViewModel
        @StateObject private var medicineStockVM: MedicineStockViewModel
       // @StateObject private var medicineDetailVM: MedicineDetailViewModel
        @StateObject private var dataStore = DataStore.shared

    init() {
        FirebaseApp.configure()
        
        // ✅ Créer le dataStore en premier
        let sharedDataStore = DataStore.shared
        
        // ✅ Créer les ViewModels avec leurs dépendances
        let session = SessionViewModel.shared
        //let login = LoginViewModel(sessionVM: session)
       // let aisleList = AisleListViewModel(sessionVM: session)
        
        // ✅ Passer les dépendances explicitement
        let stockVM = MedicineStockViewModel(
            firestoreService: FirestoreService.shared,
            dataStore: sharedDataStore
        )
        
       /* let medicineDetail = MedicineDetailViewModel(
            authService: AuthService.shared,
            firestoreService: FirestoreService.shared,
            dataStore: sharedDataStore
        )*/
        
        // ✅ Assigner les StateObjects
        _sessionVM = StateObject(wrappedValue: session)
       // _loginVM = StateObject(wrappedValue: login)
       // _aisleListVM = StateObject(wrappedValue: aisleList)
        _medicineStockVM = StateObject(wrappedValue: stockVM)
        //_medicineDetailVM = StateObject(wrappedValue: medicineDetail)
        _dataStore = StateObject(wrappedValue: sharedDataStore)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionVM)
                .environmentObject(dataStore)
                .environmentObject(medicineStockVM)
        }
    }
}

