import XCTest
@testable import PathDeck

final class ModernizationTests: XCTestCase {

    func testIndentedPathExportIsPreservedAsRawInIfBlock() {
        let script = "if [ -d \"/opt/custom/bin\" ]; then\n  export PATH=\"/opt/custom/bin:$PATH\"\nfi"
        let lines = ShellConfigParser.parse(contentsOf: script)
        XCTAssertTrue(lines.contains(.raw(content: "  export PATH=\"/opt/custom/bin:$PATH\"")))
        XCTAssertEqual(ShellConfigParser.serialize(lines), script)
    }

    func testDisabledPathExportRoundTrip() {
        let script = """
        # export PATH="/opt/disabled/bin:$PATH"
        export PATH="/opt/active/bin:$PATH"
        """
        let lines = ShellConfigParser.parse(contentsOf: script)
        XCTAssertTrue(lines.contains(.disabledPathExport(path: "/opt/disabled/bin", isPrepend: true, comment: nil)))
        XCTAssertTrue(lines.contains(.pathExport(path: "/opt/active/bin", isPrepend: true, comment: nil)))
    }

    func testSemanticVersionComparisonPreventsDowngrade() {
        let v101 = SemanticVersion(tag: "V1.0.1")!
        let v102 = SemanticVersion(tag: "v1.0.2")!
        let v110 = SemanticVersion(tag: "v1.1.0")!

        XCTAssertFalse(v101 > v101)
        XCTAssertTrue(v102 > v101)
        XCTAssertTrue(v110 > v102)
    }

    func testBackupManagerCollisionSafetyAndPermissions() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("pathdeck_test_\(UUID().uuidString)")
        let backupsDir = tmpDir.appendingPathComponent("backups")
        let sourceFile = tmpDir.appendingPathComponent(".zshrc")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        try "export TEST=\"1\"".write(to: sourceFile, atomically: true, encoding: .utf8)

        let manager = BackupManager(backupsDirectory: backupsDir)
        let first = try await manager.createBackup(for: sourceFile)
        let second = try await manager.createBackup(for: sourceFile)

        XCTAssertNotEqual(first.lastPathComponent, second.lastPathComponent)
        XCTAssertTrue(FileManager.default.fileExists(atPath: first.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: second.path))

        let dirPerms = (try FileManager.default.attributesOfItem(atPath: backupsDir.path)[.posixPermissions] as? NSNumber)?.intValue
        let filePerms = (try FileManager.default.attributesOfItem(atPath: first.path)[.posixPermissions] as? NSNumber)?.intValue
        XCTAssertEqual(dirPerms, 0o700)
        XCTAssertEqual(filePerms, 0o600)
    }

    @MainActor
    func testShellConfigServicePersistsNewAliasesAndEnvVars() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent("pathdeck_svc_\(UUID().uuidString)")
        let profileURL = tmpDir.appendingPathComponent(".zshrc")
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        try "export PATH=\"/usr/local/bin:$PATH\"\n".write(to: profileURL, atomically: true, encoding: .utf8)

        let service = ShellConfigService(autoLoad: false)
        try await service.loadConfig(from: profileURL)

        service.aliases.append(AliasItem(name: "gs", command: "git status", comment: "Status", isEnabled: true))
        service.envVars.append(EnvVarItem(key: "API_TOKEN", value: "secret123", isSensitive: true))
        service.pathItems[0].isEnabled = false

        XCTAssertTrue(service.hasUnsavedChanges)
        try await service.saveConfig()
        XCTAssertFalse(service.hasUnsavedChanges)

        let reloaded = ShellConfigService(autoLoad: false)
        try await reloaded.loadConfig(from: profileURL)
        XCTAssertEqual(reloaded.aliases.first?.name, "gs")
        XCTAssertEqual(reloaded.aliases.first?.comment, "Status")
        XCTAssertEqual(reloaded.envVars.first?.key, "API_TOKEN")
        XCTAssertEqual(reloaded.envVars.first?.isSensitive, true)
        XCTAssertEqual(reloaded.pathItems.first?.isEnabled, false)
    }
}
