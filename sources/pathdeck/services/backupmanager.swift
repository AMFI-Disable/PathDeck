import Foundation

/// Structured metadata describing a single profile restore point.
public struct BackupMetadata: Identifiable, Equatable {
    public let id: UUID
    public let url: URL
    public let filename: String
    public let timestamp: Date
    public let fileSize: Int64

    public init(id: UUID = UUID(), url: URL, filename: String, timestamp: Date, fileSize: Int64) {
        self.id = id
        self.url = url
        self.filename = filename
        self.timestamp = timestamp
        self.fileSize = fileSize
    }
}

/// Manages safekeeping and indexing backups of shell configuration profiles.
public final class BackupManager {

    private let backupsDirectory: URL

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()

    /// Initializes BackupManager.
    /// - Parameter backupsDirectory: Custom backup URL to isolate tests, defaults to ~/Library/Application Support/PathDeck/backups/
    public init(backupsDirectory: URL? = nil) {
        if let customDir = backupsDirectory {
            self.backupsDirectory = customDir
        } else {
            let fileManager = FileManager.default
            let appSupport = (try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
            self.backupsDirectory = appSupport.appendingPathComponent("PathDeck/backups", isDirectory: true)
        }
    }

    /// Asynchronously duplicates target configuration profile to our backups folder with timestamp.
    /// - Parameter fileURL: Target file URL (e.g. ~/.zshrc)
    /// - Returns: The file URL of the generated backup.
    public func createBackup(for fileURL: URL) async throws -> URL {
        let fileManager = FileManager.default

        // 1. Create backups directory if not exists with owner-only permissions (0o700)
        do {
            try fileManager.createDirectory(
                at: backupsDirectory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700]
            )
            try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: backupsDirectory.path)
        } catch {
            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 100,
                userInfo: [NSLocalizedDescriptionKey: "Restricted permissions: Failed to create backups directory at \(backupsDirectory.path). Details: \(error.localizedDescription)"]
            )
        }

        // 2. Form collision-safe timestamped backup name (e.g., .zshrc_backup_20260708_143022)
        let timestamp = Self.timestampFormatter.string(from: Date())
        let originalName = fileURL.lastPathComponent
        var backupURL = backupsDirectory.appendingPathComponent("\(originalName)_backup_\(timestamp)")
        var suffix = 1
        while fileManager.fileExists(atPath: backupURL.path) {
            backupURL = backupsDirectory.appendingPathComponent("\(originalName)_backup_\(timestamp)_\(suffix)")
            suffix += 1
        }

        // 3. Verify original file exists and is readable
        let resolvedSource = fileURL.resolvingSymlinksInPath()
        guard fileManager.fileExists(atPath: resolvedSource.path) else {
            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Restricted permissions: Target configuration file not found at: \(fileURL.path)"]
            )
        }

        guard fileManager.isReadableFile(atPath: resolvedSource.path) else {
            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Restricted permissions: Target configuration file lacks read permissions at: \(fileURL.path)"]
            )
        }

        // 4. Duplicate file and lock down permissions to owner read/write (0o600)
        do {
            try fileManager.copyItem(at: resolvedSource, to: backupURL)
            try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
        } catch {
            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 101,
                userInfo: [NSLocalizedDescriptionKey: "Restricted permissions: Failed to copy items to \(backupURL.path). Details: \(error.localizedDescription)"]
            )
        }

        return backupURL
    }

    /// Reads and indexes all existing files matching our timestamped backups pattern.
    /// - Returns: A chronologically sorted list of restore point metadata items.
    public func listBackups() throws -> [BackupMetadata] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backupsDirectory.path) else { return [] }

        let contents = try fileManager.contentsOfDirectory(
            at: backupsDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
            options: []
        )

        var backups = [BackupMetadata]()

        for url in contents {
            let filename = url.lastPathComponent
            guard filename.contains("_backup_") else { continue }

            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
            let fileSize = Int64(resourceValues.fileSize ?? 0)

            var timestamp = resourceValues.creationDate ?? Date()
            if let range = filename.range(of: "_backup_", options: .backwards) {
                let rawSuffix = String(filename[range.upperBound...])
                let tsString = rawSuffix.split(separator: "_").prefix(2).joined(separator: "_")
                if let parsedDate = Self.timestampFormatter.date(from: tsString) {
                    timestamp = parsedDate
                }
            }

            backups.append(BackupMetadata(
                url: url,
                filename: filename,
                timestamp: timestamp,
                fileSize: fileSize
            ))
        }

        return backups.sorted(by: { $0.timestamp > $1.timestamp })
    }

    /// Safely overwrites the active configuration target path with a backup restore point file.
    /// - Parameters:
    ///   - backupURL: URL location of the source backup snapshot.
    ///   - targetURL: Active destination URL profile path (e.g. ~/.zshrc).
    public func restoreBackup(from backupURL: URL, over targetURL: URL) throws {
        let fileManager = FileManager.default

        // 1. Verify backup source is readable
        guard fileManager.fileExists(atPath: backupURL.path) else {
            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Backup restore source file not found at: \(backupURL.path)"]
            )
        }

        let resolvedTarget = targetURL.resolvingSymlinksInPath()

        // 2. Verify target file destination is writable (if it exists)
        if fileManager.fileExists(atPath: resolvedTarget.path) {
            guard fileManager.isWritableFile(atPath: resolvedTarget.path) else {
                throw NSError(
                    domain: "PathDeck.BackupManager",
                    code: 403,
                    userInfo: [NSLocalizedDescriptionKey: "Target configuration file at \(targetURL.path) is locked or not writable. Restore aborted safely."]
                )
            }
        }

        // 3. Stage the backup copy beside the resolved target, preserving POSIX permissions
        let originalPermissions = (try? fileManager.attributesOfItem(atPath: resolvedTarget.path)[.posixPermissions]) as? NSNumber
        let stagedURL = resolvedTarget.deletingLastPathComponent()
            .appendingPathComponent(".pathdeck_restore_staging_\(UUID().uuidString)")

        do {
            try fileManager.copyItem(at: backupURL, to: stagedURL)
            if let perms = originalPermissions {
                try? fileManager.setAttributes([.posixPermissions: perms], ofItemAtPath: stagedURL.path)
            }

            if fileManager.fileExists(atPath: resolvedTarget.path) {
                _ = try fileManager.replaceItemAt(resolvedTarget, withItemAt: stagedURL, backupItemName: nil, options: [])
            } else {
                try fileManager.moveItem(at: stagedURL, to: resolvedTarget)
            }
        } catch {
            // Best-effort cleanup of the staged copy before surfacing the failure
            try? fileManager.removeItem(at: stagedURL)

            throw NSError(
                domain: "PathDeck.BackupManager",
                code: 102,
                userInfo: [NSLocalizedDescriptionKey: "Failed to overwrite live configuration. Details: \(error.localizedDescription)"]
            )
        }
    }
}
