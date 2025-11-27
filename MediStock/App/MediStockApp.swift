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
        @StateObject private var medicineStockVM: MedicineStockViewModel
        @StateObject private var dataStore = DataStore.shared

    init() {
        FirebaseApp.configure()
        
        let sharedDataStore = DataStore.shared
        let session = SessionViewModel.shared
        
        let stockVM = MedicineStockViewModel(
            firestoreService: FirestoreService.shared,
            dataStore: sharedDataStore
        )
        _sessionVM = StateObject(wrappedValue: session)
        _medicineStockVM = StateObject(wrappedValue: stockVM)
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

