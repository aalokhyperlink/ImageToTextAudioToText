import SwiftUI

@main
struct RunBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: RunBuddyViewModel())
        }
    }
}
