import SwiftUI

@main
struct DPIManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 680, idealWidth: 680, minHeight: 520, idealHeight: 530)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentMinSize)
    }
}
