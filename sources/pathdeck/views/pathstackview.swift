import SwiftUI

/// Renders the path priority list with native drag-and-drop reordering, disk presence validation, and persistence bindings.
public struct PathStackView: View {
    @Environment(ShellConfigService.self) private var service
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var newPath = ""
    @State private var newIsPrepend = true

    public init() {}

    public var body: some View {
        @Bindable var service = service

        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PATH Stack Studio")
                        .font(.title)
                        .bold()
                    Text("Drag directories to adjust priorities. Toggle directories to control search path discovery.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button(action: savePaths) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Save Changes", systemImage: "arrow.down.doc.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSaving)
            }
            .padding()

            Divider()

            // Add Directory Bar
            HStack(spacing: 12) {
                TextField("Directory path (e.g. /opt/homebrew/bin or ~/.local/bin)", text: $newPath)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addPath)

                Button("Browse...") {
                    pickFolder()
                }
                .buttonStyle(.bordered)

                Picker("Mode", selection: $newIsPrepend) {
                    Text("Prepend").tag(true)
                    Text("Append").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                Button(action: addPath) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add Directory")
                .disabled(newPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))

            Divider()

            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                    Spacer()
                    Button(action: { self.errorMessage = nil }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss Error")
                }
                .padding()
                .background(Color.red.opacity(0.1))
            }

            // List with drag reordering
            if service.pathItems.isEmpty {
                ContentUnavailableView(
                    "No PATH Entries",
                    systemImage: "folder.badge.plus",
                    description: Text("Add a directory above or switch profiles in the toolbar.")
                )
            } else {
                List {
                    ForEach($service.pathItems) { $item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 12) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .padding(.trailing, 4)

                                Image(systemName: item.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(item.isValid ? .green : .orange)
                                    .font(.system(size: 16))

                                Text(item.rawPath)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(item.isEnabled ? .primary : .secondary)
                                    .strikethrough(!item.isEnabled, color: .secondary)

                                Spacer()

                                Text(item.isPrepend ? "Prepend" : "Append")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(.rect(cornerRadius: 4))

                                Toggle("Enable path \(item.rawPath)", isOn: $item.isEnabled)
                                    .toggleStyle(.switch)
                                    .labelsHidden()

                                Button(role: .destructive) {
                                    service.pathItems.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Delete path \(item.rawPath)")
                            }

                            if !item.isValid {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption)
                                    Text("Directory warning: The path '\(item.rawPath)' does not exist on this machine. Shell lookups in this folder will fail.")
                                        .font(.caption2)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(.rect(cornerRadius: 4))
                                .foregroundStyle(.orange)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, 6)
                        .contextMenu {
                            Button("Copy Path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.rawPath, forType: .string)
                            }
                            Button("Delete Path", role: .destructive) {
                                service.pathItems.removeAll { $0.id == item.id }
                            }
                        }
                    }
                    .onMove { indices, newOffset in
                        service.pathItems.move(fromOffsets: indices, toOffset: newOffset)
                    }
                }
                .listStyle(.inset)
            }

            // Status bar
            HStack {
                Text("\(service.pathItems.count) total stack items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Changes are committed directly to \(service.activeProfileDisplayPath)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
    }

    private func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            newPath = url.path
        }
    }

    private func addPath() {
        let trimmed = newPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = PATHItem(rawPath: trimmed, isValid: false, isEnabled: true, isPrepend: newIsPrepend)
        service.pathItems.append(item)
        newPath = ""
        Task { await service.verifyPathsAsync() }
    }

    private func savePaths() {
        isSaving = true
        errorMessage = nil

        Task {
            do {
                try await service.saveConfig()
                isSaving = false
            } catch {
                errorMessage = "Failed to commit changes: \(error.localizedDescription)"
                isSaving = false
            }
        }
    }
}
