import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()
    private var prefsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = SpaceManager.shared.currentLabel
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemClicked)

        SpaceManager.shared.$currentSpaceID
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.statusItem.button?.title = SpaceManager.shared.currentLabel
            }
            .store(in: &cancellables)
    }

    @objc private func statusItemClicked() {
        let menu = buildMenu()
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let mgr = SpaceManager.shared

        let header = NSMenuItem(title: mgr.currentLabel, action: nil, keyEquivalent: "")
        header.isEnabled = false
        header.attributedTitle = NSAttributedString(
            string: mgr.currentLabel,
            attributes: [.font: NSFont.menuBarFont(ofSize: 0).with(weight: .semibold)]
        )
        menu.addItem(header)
        menu.addItem(.separator())

        for space in mgr.spaces {
            let isCurrent = space.id == mgr.currentSpaceID
            let check = isCurrent ? "✓ " : "    "
            let item = NSMenuItem(title: "\(check)\(space.displayLabel)", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let editItem = NSMenuItem(title: "Edit Labels…", action: #selector(openPreferences), keyEquivalent: ",")
        editItem.target = self
        menu.addItem(editItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Switchr", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return menu
    }

    @objc private func openPreferences() {
        if prefsWindow == nil {
            let view = LabelEditorView().environmentObject(SpaceManager.shared)
            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Switchr — Edit Labels"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            prefsWindow = window
        }
        prefsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private extension NSFont {
    func with(weight: NSFont.Weight) -> NSFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [NSFontDescriptor.TraitKey.weight: weight]
        ])
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
