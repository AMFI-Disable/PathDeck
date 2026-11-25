import SwiftUI

/// Ledger list displaying environment variables, enabling secrets masking, and featuring Touch ID secure unlock.
public struct EnvVarView: View {
    @Environment(ShellConfigService.self) private var service

    // Header inputs for adding variables
    @State private var newKey = ""
    @State private var newValue = ""
    @State private var newIsSensitive = false

    // UI state parameters
    @State private var searchText = ""
    @State private var unlockedIds: Set<UUID> = []

    @State private var isSaving = false
    @State private var errorMessage: String?

    public init() {}

    private var filteredVariables: Binding<[EnvVarItem]> {
        Binding(
            get: {
                if searchText.isEmpty {
                    return service.envVars
                } else {
                    let query = searchText.lowercased()
                    return service.envVars.filter { item in
                        if item.key.lowercased().contains(query) {
                            return true
                        }
                        if !item.isSensitive || unlockedIds.contains(item.id) {
                            return item.value.lowercased().contains(query)
                        }
                        return false
                    }
                }
            },
            set: { newValue in
                for item in newValue {
                    if let index = service.envVars.firstIndex(where: { $0.id == item.id }) {
                        service.envVars[index] = item
                    }
                }
            }
        )
    }

    public var body: some View {
        @Bindable var service = service

        VStack(alignment: .leading, spacing: 0) {
            // Title Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Environment Variables")
                        .font(.title)
                        .bold()
                    Text("Manage system configurations. Secure tokens, keys, and credentials behind biometrics.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()

                Button(action: saveVariables) {
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

            // Add Variable Panel
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Environment Variable")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    TextField("Name (e.g. API_KEY)", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                        .onSubmit(addNewVariable)

                    Group {
                        if newIsSensitive {
                            SecureField("Secret Value", text: $newValue)
                        } else {
                            TextField("Value", text: $newValue)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addNewVariable)

                    Toggle(isOn: $newIsSensitive) {
                        Label("Sensitive", systemImage: "lock.shield")
                    }
                    .toggleStyle(.checkbox)

                    Button(action: addNewVariable) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add Environment Variable")
                    .disabled(newKey.isEmpty || newValue.isEmpty)
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

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search variables by name...", text: $searchText)
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

            // Variables List
            if filteredVariables.wrappedValue.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "No Environment Variables",
                        systemImage: "lock.shield",
                        description: Text("Add an environment variable above to manage keys and exports.")
                    )
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                List {
                    ForEach(filteredVariables) { $item in
                        HStack(spacing: 16) {
                            if item.isSensitive {
                                Button {
                                    didTapSecureField(for: item)
                                } label: {
                                    Image(systemName: unlockedIds.contains(item.id) ? "lock.open.fill" : "lock.fill")
                                        .foregroundStyle(unlockedIds.contains(item.id) ? .green : .orange)
                                        .font(.system(size: 14))
                                        .frame(width: 16)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(unlockedIds.contains(item.id) ? "Lock \(item.key)" : "Unlock \(item.key)")
                            } else {
                                Image(systemName: "capsule")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 10))
                                    .frame(width: 16)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.key)
                                    .font(.headline)
                                    .fontWeight(.medium)

                                if item.isSensitive && !unlockedIds.contains(item.id) {
                                    Button {
                                        didTapSecureField(for: item)
                                    } label: {
                                        Text("••••••••")
                                            .font(.system(.body, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Reveal secret for \(item.key)")
                                } else {
                                    Text(item.value)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(.primary)
                                }
                            }

                            Spacer()

                            Toggle("Protect \(item.key) with biometrics", isOn: $item.isSensitive)
                                .toggleStyle(.switch)
                                .labelsHidden()

                            Button(role: .destructive) {
                                service.envVars.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete variable \(item.key)")
                        }
                        .padding(.vertical, 6)
                        .contextMenu {
                            if !item.isSensitive || unlockedIds.contains(item.id) {
                                Button("Copy Value") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item.value, forType: .string)
                                }
                            }
                            Button("Delete Variable", role: .destructive) {
                                service.envVars.removeAll { $0.id == item.id }
                            }
                        }
                        .onDisappear {
                            unlockedIds.remove(item.id)
                        }
                    }
                    .onDelete(perform: deleteVariable)
                }
                .listStyle(.inset)
            }

            // Footer Info
            HStack {
                Text("\(service.envVars.count) variables loaded")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Lock icons denote biometric protection variables")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            unlockedIds.removeAll()
        }
    }

    private func addNewVariable() {
        let key = newKey.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let val = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !key.isEmpty, !val.isEmpty else { return }
        guard ShellConfigParser.isValidEnvVarKey(key) else {
            errorMessage = "Invalid variable key '\(key)'. Start with a letter or '_' and use only letters, numbers, or '_'."
            return
        }
        errorMessage = nil

        let newItem = EnvVarItem(
            key: key,
            value: val,
            isSensitive: newIsSensitive
        )

        service.envVars.append(newItem)

        // Reset fields
        newKey = ""
        newValue = ""
        newIsSensitive = false
    }

    private func deleteVariable(at offsets: IndexSet) {
        let items = filteredVariables.wrappedValue
        let idsToDelete = Set(offsets.compactMap { idx in
            items.indices.contains(idx) ? items[idx].id : nil
        })
        service.envVars.removeAll { idsToDelete.contains($0.id) }
    }

    /// Biometric credential unlock action hook calling local authentication asynchronously.
    private func didTapSecureField(for item: EnvVarItem) {
        if unlockedIds.contains(item.id) {
            // Lock again instantly
            unlockedIds.remove(item.id)
        } else {
            // Asynchronously request Touch ID authentication
            Task {
                let reason = "Verify identity to reveal sensitive variable '\(item.key)'"
                let success = await TouchIDService.shared.authenticateUser(reason: reason)
                if success {
                    _ = await MainActor.run {
                        unlockedIds.insert(item.id)
                    }
                }
            }
        }
    }

    private func saveVariables() {
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
