import Foundation
import LocalAuthentication

/// Abstraction for biometric/passcode authentication so views and tests can inject mocks.
public protocol BiometricAuthenticating: Sendable {
    func authenticateUser(reason: String) async -> Bool
}

/// A thread-safe biometric and passcode authentication utility using Apple's LocalAuthentication framework.
public final class TouchIDService: BiometricAuthenticating, @unchecked Sendable {

    public static let shared = TouchIDService()

    private let stateLock = NSLock()
    private var isAuthenticating = false

    private init() {}

    /// Asynchronously authenticates user utilizing Touch ID, falling back to system password passcode prompt if unavailable.
    /// - Parameter reason: Contextual explanation presented to the user.
    /// - Returns: True if user authenticated successfully, false otherwise.
    public func authenticateUser(reason: String) async -> Bool {
        let shouldProceed: Bool = stateLock.withLock {
            if isAuthenticating { return false }
            isAuthenticating = true
            return true
        }
        guard shouldProceed else { return false }
        defer {
            stateLock.withLock { isAuthenticating = false }
        }

        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
