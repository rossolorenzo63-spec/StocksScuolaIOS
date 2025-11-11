import SwiftUI

@main
struct StocksScuolaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // This forces the dark theme to match your original app
                .preferredColorScheme(.dark)
        }
    }
}
