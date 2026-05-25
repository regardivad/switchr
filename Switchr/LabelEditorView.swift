import SwiftUI

struct LabelEditorView: View {
    @EnvironmentObject var manager: SpaceManager
    @State private var editingLabels: [String: String] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Desktop Labels")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 4)

            Text("Rename your desktops. Leave blank to keep the default.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(manager.spaces) { space in
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.on.rectangle")
                                .foregroundColor(space.id == manager.currentSpaceID ? .accentColor : .secondary)
                                .frame(width: 20)

                            Text("Desktop \(space.index)")
                                .foregroundColor(.secondary)
                                .frame(width: 72, alignment: .leading)
                                .lineLimit(1)

                            TextField("Desktop \(space.index)", text: binding(for: space))
                                .textFieldStyle(.roundedBorder)
                                .onSubmit { save(space: space) }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }

            Divider()

            HStack {
                if manager.spaces.isEmpty {
                    Text("No desktops detected")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                Spacer()
                Button("Refresh") {
                    manager.refresh()
                    syncFromManager()
                }
                .buttonStyle(.borderless)
                Button("Save") {
                    saveAll()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(minWidth: 360, minHeight: 260)
        .onAppear { syncFromManager() }
        .onReceive(manager.$spaces) { _ in syncFromManager() }
    }

    private func binding(for space: SpaceInfo) -> Binding<String> {
        Binding(
            get: { editingLabels[space.id] ?? "" },
            set: { editingLabels[space.id] = $0 }
        )
    }

    private func syncFromManager() {
        for space in manager.spaces {
            if editingLabels[space.id] == nil {
                editingLabels[space.id] = space.customLabel
            }
        }
    }

    private func save(space: SpaceInfo) {
        let label = editingLabels[space.id] ?? ""
        manager.setLabel(label, for: space.id)
    }

    private func saveAll() {
        for space in manager.spaces {
            let label = editingLabels[space.id] ?? ""
            manager.setLabel(label, for: space.id)
        }
    }
}
