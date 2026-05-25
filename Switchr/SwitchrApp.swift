import SwiftUI

@main
struct SwitchrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            LabelEditorView()
                .environmentObject(SpaceManager.shared)
        }
    }
}
