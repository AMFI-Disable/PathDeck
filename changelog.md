# Changelog

All notable changes, features, and release history for PathDeck Studio are documented in this file.

---

## [1.0.1] - Maintenance And Diagnostic Release

### Fixed

- **Task Info Count Resolution**: Corrected task info count derivation to ensure accurate system metrics across macOS task monitors.
- **CI Diagnostics Reporting**: Surfaced detailed test diagnostics and logs in automated testing pipelines.

---

## [1.0.0] - Initial Production Release

PathDeck is a native macOS developer studio built in SwiftUI to visually inspect, organize, audit, and safely back up shell environment configurations (`~/.zshrc` and `~/.bash_profile`).

### Added

#### PATH Stack Studio

- **Visual Path Prioritization**: Interactive drag-and-drop list to reorder system search paths (`$PATH`).
- **Disk Existence Verification**: Automatic background validation with color-coded status badges (green for valid directories, orange warning for dead or missing paths).
- **Asynchronous Validation**: File system checks offloaded to non-blocking background threads to maintain 60 FPS UI responsiveness.

#### Alias Studio

- **Shortcut Registry**: Visual management for custom shell aliases and commands.
- **Clean Deactivation**: Toggle shortcuts off cleanly by commenting them out in configuration files without data loss.

#### Environment Variables

- **Biometric Protection**: Lock sensitive local environment variables behind Touch ID authentication.
- **In-Memory Masking**: Automatic masking of sensitive secrets as secure bullet characters (`••••••••`).
- **Per-Row Verification**: Granular authentication requirement to reveal confidential tokens.

#### Backup And Safety System

- **Pre-Write Snapshots**: Automatic timestamped configuration backups saved to Application Support prior to modifying shell profiles.
- **One-Click Restore**: Instant rollback functionality to revert to previous profile states safely.
- **Ultra-Light Memory Profile**: Zero third-party dependencies, keeping memory consumption strictly under 10MB.
