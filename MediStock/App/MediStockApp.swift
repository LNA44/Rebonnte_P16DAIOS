//
//  MediStockApp.swift
//  MediStock
//
//  Created by Vincent Saluzzo on 28/05/2024.
//

import SwiftUI

@main
struct MediStockApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var sessionVM = SessionViewModel() //ajout de State pour éviter une memoryleak au lancement de l'app
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionVM)
        }
    }
}

