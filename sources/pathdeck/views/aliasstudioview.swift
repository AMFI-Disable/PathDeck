import SwiftUI

/// A searchable shortcut command studio enabling alias addition, status toggling, and comment editing.
public struct AliasStudioView: View {
    @Environment(ShellConfigService.self) private var service

    // Header inputs
    @State private var newName = ""
    @State private var newCommand = ""
    @State private var newComment = ""

    // Search query
    @State private var searchText = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    public init() {}

    private var filteredAliases: Binding<[AliasItem]> {
        Binding(
            get: {
                if searchText.isEmpty {
                    return service.aliases
                } else {
                    let query = searchText.lowercased()
                    return service.aliases.filter {
                        $0.name.lowercased().contains(query) ||
                        $0.command.lowercased().contains(query) ||
                        ($0.comment?.lowercased().contains(query) ?? false)
                    }
                }
            },
            set: { newValue in
                // Sync back mutations to the source array matching by id
                for item in newValue {
                    if let index = service.aliases.firstIndex(where: { $0.id == item.id }) {
                        service.aliases[index] = item
                    }
                }
            }
        )
    }

    public var body: some View {
        @Bindable var service = service

        VStack(alignment: .leading, spacing: 0) {
            // Header panel
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alias Studio")
                        .font(.title)
                        .bold()
                    Text("Toggle shortcuts to comment them out without deleting. Add new commands instantly.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button(action: saveAliases) {
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

            // Add New Alias Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Add New Shortcut")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    TextField("Name (e.g. gs)", text: $newName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                        .onSubmit(addNewAlias)

                    TextField("Target Command (e.g. git status)", text: $newCommand)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addNewAlias)

                    TextField("Comment (optional)", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                        .onSubmit(addNewAlias)

                    Button(action: addNewAlias) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Alias")
                    .disabled(newName.isEmpty || newCommand.isEmpty)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.4))

            Divider()

            // Error panel if any
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
                Divider()
            }

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search aliases by name or command...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear Search")
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .clipShape(.rect(cornerRadius: 6))
            .padding([.horizontal, .top])

            // Aliases list
            if filteredAliases.wrappedValue.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Aliases Configured",
                        systemImage: "terminal",
                        description: Text("Add a shell shortcut above to get started.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(filteredAliases) { $item in
                        HStack(spacing: 16) {
                            Circle()
                                .fill(item.isEnabled ? Color.blue : Color.gray)
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(item.name)
                                        .font(.headline)
                                        .foregroundStyle(item.isEnabled ? .primary : .secondary)

                                    Text("→")
                                        .foregroundStyle(.secondary)

                                    Text(item.command)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(item.isEnabled ? .primary : .secondary)
                                }

                                if let comment = item.comment, !comment.isEmpty {
                                    Text("# \(comment)")
                                        .font(.caption)
                                        .italic()
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Toggle("Enable alias \(item.name)", isOn: $item.isEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()

                            Button(role: .destructive) {
                                service.aliases.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete alias \(item.name)")
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button("Copy Command") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.command, forType: .string)
                            }
                            Button("Delete Alias", role: .destructive) {
                                service.aliases.removeAll { $0.id == item.id }
                            }
                        }
                    }
                    .onDelete(perform: deleteAlias)
                }
                .listStyle(.inset)
            }

            // Footer Info
            HStack {
                Text("\(service.aliases.count) aliases loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Swipe or delete rows to remove")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
    }

    private func addNewAlias() {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cmd = newCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let comment = newComment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty, !cmd.isEmpty else { return }
        guard ShellConfigParser.isValidAliasName(name) else {
            errorMessage = "Invalid alias name '\(name)'. Use letters, numbers, '.', '-', or '_' without spaces."
            return
        }
        errorMessage = nil

        let newItem = AliasItem(
            name: name,
            command: cmd,
            comment: comment.isEmpty ? nil : comment,
            isEnabled: true
        )

        service.aliases.append(newItem)

        // Reset inputs
        newName = ""
        newCommand = ""
        newComment = ""
    }

    private func deleteAlias(at offsets: IndexSet) {
        let items = filteredAliases.wrappedValue
        let idsToDelete = Set(offsets.compactMap { idx in
            items.indices.contains(idx) ? items[idx].id : nil
        })
        service.aliases.removeAll { idsToDelete.contains($0.id) }
    }

    private func saveAliases() {
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
