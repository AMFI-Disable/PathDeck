# 🧭 PathDeck

<div align="center">

**The Modern Native macOS Developer Studio For Shell Environment Management**  
*Lightning-fast, native SwiftUI GUI companion for visual PATH prioritization, alias studio, and zero-loss backup restores.*

[![Platform: macOS Sonoma+](https://img.shields.io/badge/Platform-macOS%2014%2B%20(Sonoma%20%2F%20Sequoia)-blue.svg?style=flat-square&logo=apple)](https://apple.com)
[![Swift: 5.10+](https://img.shields.io/badge/Swift-5.10%2B-orange.svg?style=flat-square&logo=swift)](https://swift.org)
[![Release: v1.0.1](https://img.shields.io/badge/Release-v1.0.1-blue.svg?style=flat-square&logo=github)](https://github.com/AMFI-Disable/PathDeck/releases)
[![Tests: Passing](https://img.shields.io/badge/Tests-Passing%20(100%25)-success.svg?style=flat-square&logo=checkmarx)](#automated-tests-and-quality-assurance)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](license)
[![Pricing: Free & Open-Source](https://img.shields.io/badge/Pricing-100%25%20Free%20%26%20Open%20Source-success.svg?style=flat-square)](#overview-and-core-value)
[![Privacy: Zero Telemetry](https://img.shields.io/badge/Privacy-Zero%20Telemetry%20%2F%20100%25%20Local-purple.svg?style=flat-square)](#privacy-and-security-first)

</div>

> [!NOTE]
> **Project Archived & Sunset Notice**
> PathDeck has reached end-of-life and is officially archived. The final standalone release is [v1.0.1](https://github.com/AMFI-Disable/PathDeck/releases/tag/v1.0.1). The repository remains available in read-only mode for historical reference. See the [farewell changelog](changelog.md) for final release notes. No further updates, issues, or pull requests will be accepted.

---

## 🧭 Table Of Contents

- [Overview & Core Value](#overview-and-core-value)
- [Key Features](#key-features)
- [Installation Guide](#installation-guide)
- [Automated Tests & Quality Assurance](#automated-tests-and-quality-assurance)
- [Privacy & Security First](#privacy-and-security-first)
- [License & Open Source](#license-and-open-source)

---

## ⚡ Overview And Core Value <a id="overview-and-core-value"></a>

> **Project status — final standalone release.** V1.0.1 is the last independently shipped version of PathDeck Studio; the project is moving into a parent application for integration. See the [changelog](changelog.md) for the farewell release notes.

PathDeck is a premium, native macOS developer studio designed to visually manage, prioritize, audit, and safely back up shell environment configurations (specifically targeting `~/.zshrc` and `~/.bash_profile`).

Every developer on a Mac deals with shell profiles, but managing them remains trapped in terminal editors. PathDeck transforms this experience by reading these hidden configuration files and mapping them directly to a safe, modern SwiftUI interface.

---

## 🚀 Key Features <a id="key-features"></a>

- **PATH Stack Studio**: Drag-and-drop to prioritize search pathways with visual status dot indicators (Green checkmark denotes folders that exist on disk; orange warning signals dead/broken folders). Offloads disk validation tasks to background threads to prevent UI lag.
- **Alias Studio**: Register custom command shortcuts. Deactivate aliases cleanly by commenting them out in `~/.zshrc` without deleting them.
- **Environment Variables**: Lock sensitive local environment variables behind Touch ID biometrics. Revealing secrets requires verification on a per-row basis. Auto-masks secrets in-memory as bullets (`••••••••`).
- **Safety Restores & Backups**: Every write command creates an automated timestamped backup of the config file in standard Library Application Support directories prior to commits. Recover snapshots securely with 1-click.
- **Ultra-Light Footprint**: Operates entirely in memory with zero external frameworks, keeping operational states strictly under 10MB.

---

## 📦 Installation Guide <a id="installation-guide"></a>

### Manual DMG Package (GitHub Releases)

Download the verified `.dmg` package from [GitHub Releases](https://github.com/AMFI-Disable/PathDeck/releases). Verify the SHA-256 checksum after download:

```bash
shasum -a 256 pathdeck-1.0.1.dmg
```

#### macOS Gatekeeper Clearance (Unnotarized Open-Source Build)

Because PathDeck is an open-source build provided without a paid Apple Developer ID certificate ($99/year), macOS Gatekeeper quarantines downloaded application bundles on first launch.

To clear the quarantine flag via Terminal:

```bash
sudo xattr -r -c /Applications/PathDeck.app
```

Alternatively, open **System Settings > Privacy & Security**, scroll down to the Security section, and click **Open Anyway** (or hold `Control` while clicking the app in Finder and select **Open**).

### Build From Source

PathDeck is built using pure Swift 5.10+ targeting macOS 14+. To compile and install locally:

```bash
git clone https://github.com/AMFI-Disable/PathDeck.git
cd PathDeck
./scripts/build.sh
```

The built application bundle will be located at `./PathDeck.app`.

---

## 🧪 Automated Tests And Quality Assurance <a id="automated-tests-and-quality-assurance"></a>

To run our test suites containing edge-case tokenizer parser and backup restoration validations:

```bash
swift test
```

---

## 🛡️ Privacy And Security First <a id="privacy-and-security-first"></a>

- **Zero Telemetry**: No third-party network pings, tracking cookies, or diagnostic phoning home.
- **Local-First Execution**: All shell profile reads, backups, and environment parses occur 100% locally on device.
- **Biometric Security**: Sensitive environment variable values are locked behind Touch ID authentication.

---

## 📄 License And Open Source <a id="license-and-open-source"></a>

Licensed under the [MIT License](license). Copyright (c) 2026 AMFI-Disable.
