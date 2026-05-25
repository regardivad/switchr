import SwiftUI

@main
struct SwitchrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // All UI is managed by AppDelegate via NSStatusItem.
        // Settings scene is omitted; preferences window is a plain NSWindow.
        Settings { EmptyView() }
    }
}
