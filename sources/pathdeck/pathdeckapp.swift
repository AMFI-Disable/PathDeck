import SwiftUI
import AppKit

/// Application delegate hook to terminate application immediately after main window is closed.
public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

/// Entry point for the PathDeck native macOS application.
@main
struct PathDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // Instantiate our central state coordinators
    @State private var service = ShellConfigService()
    @State private var updater = UpdaterService()

    @Environment(\.openWindow) private var openWindow

    init() {
        // Make the app a regular foreground GUI app, enabling dock icon and window focus
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        Window("PathDeck Studio", id: "main") {
            MainView()
                .environment(service)
                .environment(updater)
                .preferredColorScheme(.dark)
        }
        .commands {
            // Customize Help menu to trigger manual view window
            CommandGroup(replacing: .help) {
                Button("PathDeck Help Manual") {
                    openWindow(id: "help-manual")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        // Help Manual Window Group
        Window("PathDeck Help Manual", id: "help-manual") {
            HelpView()
                .preferredColorScheme(.dark)
        }
    }
}
