import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionViewModel
  
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

