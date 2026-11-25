import Darwin
import Foundation
import Observation

/// Coordinates in-memory state tracking, files loading, and commits.
@MainActor
@Observable
public final class ShellConfigService {

    public var activeFileURL: URL?
    public var parsedLines: [ConfigLine] = []

    // UI bindable properties
    public var pathItems: [PATHItem] = []
    public var aliases: [AliasItem] = []
    public var envVars: [EnvVarItem] = []

    public var memoryFootprintMB: Double = 0.0

    // App-wide error handling state bound to UI sheets
    public var errorMessage: String?

    private var savedPathItems: [PATHItem] = []
    private var savedAliases: [AliasItem] = []
    private var savedEnvVars: [EnvVarItem] = []
    private var lastLoadedModificationDate: Date?

    private let backupManager = BackupManager()

    public var hasUnsavedChanges: Bool {
        pathItems != savedPathItems || aliases != savedAliases || envVars != savedEnvVars
    }

    public var activeProfileDisplayPath: String {
        guard let url = activeFileURL else { return "~/.zshrc" }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path.hasPrefix(home) {
            return "~" + url.path.dropFirst(home.count)
        }
        return url.path
    }

    public init(autoLoad: Bool = true) {
        locateActiveProfile()
        let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if autoLoad && !isRunningTests, let url = activeFileURL {
            Task {
                try? await loadConfig(from: url)
            }
        }
    }

    /// Lists standard zsh and bash profile files in the user's home directory.
    public func availableProfiles(homeDirectory: URL? = nil) -> [ShellProfile] {
        let fm = FileManager.default
        let homeDir = homeDirectory ?? fm.homeDirectoryForCurrentUser
        let names = [".zshrc", ".zprofile", ".zshenv", ".bash_profile", ".bashrc"]
        return names.map { name in
            let url = homeDir.appendingPathComponent(name)
            return ShellProfile(url: url, name: name, exists: fm.fileExists(atPath: url.path))
        }
    }

    /// Checks for the presence of ~/.zshrc, falling back to ~/.bash_profile when
    /// no zsh configuration exists, and defaults to ~/.zshrc for fresh machines.
    /// - Parameter homeDirectory: Overrides the user's home directory for isolated testing.
    public func locateActiveProfile(homeDirectory: URL? = nil) {
        let fileManager = FileManager.default
        let homeDir = homeDirectory ?? fileManager.homeDirectoryForCurrentUser
        let zshrcURL = homeDir.appendingPathComponent(".zshrc")
        let bashProfileURL = homeDir.appendingPathComponent(".bash_profile")

        if fileManager.fileExists(atPath: zshrcURL.path) {
            self.activeFileURL = zshrcURL
        } else if fileManager.fileExists(atPath: bashProfileURL.path) {
            self.activeFileURL = bashProfileURL
        } else {
            self.activeFileURL = zshrcURL
        }
    }

    /// Asynchronously parses target profile from disk inside try-catch bounds.
    /// - Parameter url: Target file url.
    public func loadConfig(from url: URL) async throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try "".write(to: url, atomically: true, encoding: .utf8)
        }

        do {
            let resolvedURL = url.resolvingSymlinksInPath()
            let content = try String(contentsOf: resolvedURL, encoding: .utf8)
            let attrs = try? fileManager.attributesOfItem(atPath: resolvedURL.path)
            let modDate = attrs?[.modificationDate] as? Date
            let lines = ShellConfigParser.parse(contentsOf: content)

            self.activeFileURL = url
            self.parsedLines = lines
            self.lastLoadedModificationDate = modDate
            self.errorMessage = nil

            var paths = [PATHItem]()
            var loadedAliases = [AliasItem]()
            var variables = [EnvVarItem]()

            for line in lines {
                switch line {
                case .pathExport(let path, let isPrepend, _):
                    paths.append(PATHItem(rawPath: path, isValid: false, isEnabled: true, isPrepend: isPrepend))
                case .disabledPathExport(let path, let isPrepend, _):
                    paths.append(PATHItem(rawPath: path, isValid: false, isEnabled: false, isPrepend: isPrepend))
                case .alias(let name, let value, let isEnabled, let comment):
                    loadedAliases.append(AliasItem(name: name, command: value, comment: comment, isEnabled: isEnabled))
                case .envVar(let name, let value, let isSensitive, _):
                    variables.append(EnvVarItem(key: name, value: value, isSensitive: isSensitive))
                default:
                    break
                }
            }

            self.pathItems = paths
            self.aliases = loadedAliases
            self.envVars = variables
            self.savedPathItems = paths
            self.savedAliases = loadedAliases
            self.savedEnvVars = variables

            updateMemoryUsage()

            await verifyPathsAsync()
        } catch {
            self.errorMessage = "Failed to load shell configuration file: \(error.localizedDescription)"
            throw error
        }
    }

    /// Scans every entry in the pathItems stack asynchronously on a background thread.
    public func verifyPathsAsync() async {
        let itemsToVerify = self.pathItems

        let validityByID = await Task.detached(priority: .background) { () -> [UUID: Bool] in
            let fm = FileManager.default
            let home = fm.homeDirectoryForCurrentUser.path
            var results = [UUID: Bool]()
            for item in itemsToVerify {
                let withHome = item.rawPath
                    .replacingOccurrences(of: "${HOME}", with: home)
                    .replacingOccurrences(of: "$HOME", with: home)
                let expanded = (withHome as NSString).expandingTildeInPath
                var isDir: ObjCBool = false
                results[item.id] = fm.fileExists(atPath: expanded, isDirectory: &isDir) && isDir.boolValue
            }
            return results
        }.value

        for idx in self.pathItems.indices {
            if let valid = validityByID[self.pathItems[idx].id] {
                self.pathItems[idx].isValid = valid
            }
        }
        for idx in self.savedPathItems.indices {
            if let valid = validityByID[self.savedPathItems[idx].id] {
                self.savedPathItems[idx].isValid = valid
            }
        }
    }

    /// Commits local changes to disk after executing safety backups, catching any write errors.
    public func saveConfig(forceOverwrite: Bool = false) async throws {
        guard let fileURL = activeFileURL else {
            let err = NSError(
                domain: "PathDeck.ShellConfigService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No active configuration file loaded to write to."]
            )
            self.errorMessage = err.localizedDescription
            throw err
        }

        let resolvedURL = fileURL.resolvingSymlinksInPath()
        let fm = FileManager.default

        if !forceOverwrite,
           let lastDate = lastLoadedModificationDate,
           let attrs = try? fm.attributesOfItem(atPath: resolvedURL.path),
           let currentDate = attrs[.modificationDate] as? Date,
           currentDate > lastDate.addingTimeInterval(0.001) {
            let err = NSError(
                domain: "PathDeck.ShellConfigService",
                code: 409,
                userInfo: [NSLocalizedDescriptionKey: "The file \(fileURL.lastPathComponent) was modified externally. Reload before saving to avoid overwriting external changes."]
            )
            self.errorMessage = err.localizedDescription
            throw err
        }

        do {
            _ = try await backupManager.createBackup(for: resolvedURL)

            var updatedLines = [ConfigLine]()

            var pathMetadata = [String: (isPrepend: Bool, comment: String?)]()
            for line in parsedLines {
                switch line {
                case .pathExport(let path, let isPrepend, let comment),
                     .disabledPathExport(let path, let isPrepend, let comment):
                    if pathMetadata[path] == nil {
                        pathMetadata[path] = (isPrepend, comment)
                    }
                default:
                    break
                }
            }

            var remainingAliases = aliases
            var remainingEnvVars = envVars

            for line in parsedLines {
                switch line {
                case .pathExport, .disabledPathExport:
                    continue
                case .alias(let name, _, _, _):
                    if let idx = remainingAliases.firstIndex(where: { $0.name == name }) {
                        let updated = remainingAliases.remove(at: idx)
                        updatedLines.append(.alias(name: updated.name, value: updated.command, isEnabled: updated.isEnabled, comment: updated.comment))
                    }
                case .envVar(let name, _, _, let comment):
                    if let idx = remainingEnvVars.firstIndex(where: { $0.key == name }) {
                        let updated = remainingEnvVars.remove(at: idx)
                        updatedLines.append(.envVar(name: updated.key, value: updated.value, isSensitive: updated.isSensitive, comment: comment))
                    }
                default:
                    updatedLines.append(line)
                }
            }

            for newAlias in remainingAliases {
                updatedLines.append(.alias(name: newAlias.name, value: newAlias.command, isEnabled: newAlias.isEnabled, comment: newAlias.comment))
            }

            for newEnvVar in remainingEnvVars {
                updatedLines.append(.envVar(name: newEnvVar.key, value: newEnvVar.value, isSensitive: newEnvVar.isSensitive, comment: nil))
            }

            for item in pathItems {
                let metadata = pathMetadata[item.rawPath]
                let isPrepend = metadata?.isPrepend ?? item.isPrepend
                let comment = metadata?.comment
                if item.isEnabled {
                    updatedLines.append(.pathExport(path: item.rawPath, isPrepend: isPrepend, comment: comment))
                } else {
                    updatedLines.append(.disabledPathExport(path: item.rawPath, isPrepend: isPrepend, comment: comment))
                }
            }

            let contents = ShellConfigParser.serialize(updatedLines)
            let originalPerms = (try? fm.attributesOfItem(atPath: resolvedURL.path)[.posixPermissions]) as? NSNumber
            try contents.write(to: resolvedURL, atomically: true, encoding: .utf8)
            if let perms = originalPerms {
                try? fm.setAttributes([.posixPermissions: perms], ofItemAtPath: resolvedURL.path)
            }

            try await loadConfig(from: fileURL)
            self.errorMessage = nil
        } catch {
            self.errorMessage = "Failed to compile or save configuration: \(error.localizedDescription)"
            throw error
        }
    }

    /// Restores a historical backup snapshot file over our active configuration file safely.
    /// - Parameter backupURL: The source backup snapshot location.
    public func restoreConfig(from backupURL: URL) async throws {
        guard let fileURL = activeFileURL else {
            let err = NSError(
                domain: "PathDeck.ShellConfigService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "No active configuration profile loaded to restore over."]
            )
            await MainActor.run {
                self.errorMessage = err.localizedDescription
            }
            throw err
        }

        do {
            try backupManager.restoreBackup(from: backupURL, over: fileURL)
            try await loadConfig(from: fileURL)
            await MainActor.run {
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Restore failed: \(error.localizedDescription)"
            }
            throw error
        }
    }

    /// Measures the live resident memory footprint of this process for dashboard diagnostics.
    public func updateMemoryUsage() {
        self.memoryFootprintMB = Self.currentResidentFootprintMB()
    }

    /// Reads the kernel-reported resident set size (in megabytes) for the current task.
    private static func currentResidentFootprintMB() -> Double {
        var info = mach_task_basic_info()
        // MACH_TASK_BASIC_INFO_COUNT is a sizeof-based C macro the Swift importer
        // cannot surface, so derive the count from the struct layout instead.
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { infoPointer in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), integerPointer, &count)
            }
        }

        guard result == KERN_SUCCESS else { return 0.0 }
        return Double(info.resident_size) / (1024.0 * 1024.0)
    }
}
