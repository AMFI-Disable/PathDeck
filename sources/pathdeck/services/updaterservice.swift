import Foundation
import Observation

/// Parses and compares numeric SemVer tags (e.g. `V1.0.1`, `v1.2.0`).
public struct SemanticVersion: Comparable, Equatable {
    public let major: Int
    public let minor: Int
    public let patch: Int

    public init?(tag: String) {
        var cleaned = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("v") || cleaned.hasPrefix("V") {
            cleaned.removeFirst()
        }
        let core = cleaned.split(separator: "-", maxSplits: 1).first.map(String.init) ?? cleaned
        let parts = core.split(separator: ".").compactMap { Int($0) }
        guard !parts.isEmpty else { return nil }
        self.major = parts[0]
        self.minor = parts.count > 1 ? parts[1] : 0
        self.patch = parts.count > 2 ? parts[2] : 0
    }

    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

/// Handles checking GitHub Releases API for new updates.
@MainActor
@Observable
public final class UpdaterService {

    public var isUpdateAvailable: Bool = false
    public var latestVersion: String?
    public var isChecking: Bool = false
    public var errorMessage: String?

    public let currentVersion = AppVersion.current
    private var lastCheckedAt: Date?

    public init() {}

    /// Queries GitHub Releases API asynchronously to check for newer version tags.
    public func checkForUpdates(force: Bool = false) async {
        guard !isChecking else { return }
        if !force, let last = lastCheckedAt, Date().timeIntervalSince(last) < 600 {
            return
        }

        isChecking = true
        errorMessage = nil
        defer { isChecking = false }

        let urlString = "https://api.github.com/repos/AMFI-Disable/PathDeck/releases/latest"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("PathDeck-App-Updater", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return
            }

            struct ReleaseResponse: Decodable {
                let tag_name: String
            }

            let release = try JSONDecoder().decode(ReleaseResponse.self, from: data)
            let latestTag = release.tag_name.trimmingCharacters(in: .whitespacesAndNewlines)

            self.latestVersion = latestTag
            self.lastCheckedAt = Date()

            if let latest = SemanticVersion(tag: latestTag),
               let current = SemanticVersion(tag: currentVersion) {
                self.isUpdateAvailable = latest > current
            } else {
                self.isUpdateAvailable = false
            }
        } catch {
            self.errorMessage = "Check failed: \(error.localizedDescription)"
        }
    }
}
