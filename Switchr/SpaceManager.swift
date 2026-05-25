import Cocoa
import Combine

// Private CoreGraphics window-server APIs.
// CGSCopyManagedDisplaySpaces returns one dict per display, each containing
// a "Spaces" array and a "Current Space" entry keyed by uuid64.
// These have been stable since macOS 10.11 and survive across reboots.
private typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ cid: CGSConnectionID) -> CFArray?

struct SpaceInfo: Identifiable, Equatable {
    let id: String      // uuid64 — stable across reboots
    let index: Int      // 1-based position among normal desktops
    var customLabel: String

    var displayLabel: String { customLabel.isEmpty ? "Desktop \(index)" : customLabel }
}

final class SpaceManager: ObservableObject {
    static let shared = SpaceManager()

    @Published private(set) var spaces: [SpaceInfo] = []
    @Published private(set) var currentSpaceID: String = ""

    private let labelsKey = "com.switchr.spaceLabels"

    var currentSpace: SpaceInfo? { spaces.first { $0.id == currentSpaceID } }
    var currentLabel: String { currentSpace?.displayLabel ?? "Desktop" }

    private init() {
        refresh()
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(onSpaceChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    @objc private func onSpaceChange() {
        DispatchQueue.main.async { self.refresh() }
    }

    func refresh() {
        let cid = CGSMainConnectionID()
        guard let raw = CGSCopyManagedDisplaySpaces(cid) as? [[String: Any]] else { return }

        let saved = UserDefaults.standard.dictionary(forKey: labelsKey) as? [String: String] ?? [:]
        var result: [SpaceInfo] = []
        var activeID = ""
        var idx = 0

        for display in raw {
            let spaceList = display["Spaces"] as? [[String: Any]] ?? []
            let current = display["Current Space"] as? [String: Any] ?? [:]
            if let uuid = current["uuid64"] as? String, !uuid.isEmpty {
                activeID = uuid
            }
            for space in spaceList {
                guard let uuid = space["uuid64"] as? String,
                      (space["type"] as? Int ?? 0) == 0 else { continue }
                idx += 1
                result.append(SpaceInfo(id: uuid, index: idx, customLabel: saved[uuid] ?? ""))
            }
        }

        spaces = result
        if !activeID.isEmpty { currentSpaceID = activeID }
    }

    func setLabel(_ label: String, for spaceID: String) {
        var saved = UserDefaults.standard.dictionary(forKey: labelsKey) as? [String: String] ?? [:]
        saved[spaceID] = label
        UserDefaults.standard.set(saved, forKey: labelsKey)
        if let i = spaces.firstIndex(where: { $0.id == spaceID }) {
            spaces[i].customLabel = label
        }
    }
}
