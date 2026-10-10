import XCTest
@testable import PathDeck

final class PathDeckTests: XCTestCase {
    func testDay1ModelsCompilation() throws {
        let pathItem = PATHItem(rawPath: "/usr/local/bin", isValid: true, isEnabled: true)
        XCTAssertEqual(pathItem.rawPath, "/usr/local/bin")
        XCTAssertTrue(pathItem.isValid)
        XCTAssertTrue(pathItem.isEnabled)
        XCTAssertTrue(pathItem.isPrepend, "PATH entries must default to prepend semantics.")

        let appendItem = PATHItem(rawPath: "/opt/local/bin", isPrepend: false)
        XCTAssertFalse(appendItem.isPrepend, "PATH append direction must round-trip through the model.")

        let aliasItem = AliasItem(name: "ll", command: "ls -la", comment: "List details")
        XCTAssertEqual(aliasItem.name, "ll")
        XCTAssertEqual(aliasItem.command, "ls -la")
        XCTAssertEqual(aliasItem.comment, "List details")

        let envVarItem = EnvVarItem(key: "API_KEY", value: "secret", isSensitive: true)
        XCTAssertEqual(envVarItem.key, "API_KEY")
        XCTAssertEqual(envVarItem.value, "secret")
        XCTAssertTrue(envVarItem.isSensitive)
    }

    /// Validates that active profile detection prefers ~/.zshrc, honors ~/.bash_profile
    /// as documented, and defaults to ~/.zshrc on machines with neither file.
    func testActiveProfileFallbackResolution() throws {
        let fileManager = FileManager.default
        let mockHome = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: mockHome, withIntermediateDirectories: true)

        defer {
            try? fileManager.removeItem(at: mockHome)
        }

        let service = ShellConfigService()

        // Case 1: Neither file exists — default to ~/.zshrc
        service.locateActiveProfile(homeDirectory: mockHome)
        XCTAssertEqual(service.activeFileURL?.lastPathComponent, ".zshrc")

        // Case 2: Only ~/.bash_profile exists — fall back to it as documented
        let bashProfile = mockHome.appendingPathComponent(".bash_profile")
        try "export EDITOR=\"vim\"\n".write(to: bashProfile, atomically: true, encoding: .utf8)
        service.locateActiveProfile(homeDirectory: mockHome)
        XCTAssertEqual(service.activeFileURL?.lastPathComponent, ".bash_profile")

        // Case 3: Both files exist — ~/.zshrc always wins priority
        let zshrc = mockHome.appendingPathComponent(".zshrc")
        try "export EDITOR=\"nano\"\n".write(to: zshrc, atomically: true, encoding: .utf8)
        service.locateActiveProfile(homeDirectory: mockHome)
        XCTAssertEqual(service.activeFileURL?.lastPathComponent, ".zshrc")
    }
}
