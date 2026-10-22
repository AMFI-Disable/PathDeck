# PathDeck Studio: macOS Distribution Guide

PathDeck is a premium, native macOS developer studio designed to visually manage, prioritize, and safely backup shell configurations (specifically targeting `~/.zshrc` and `~/.bash_profile`).

---

## Technical Specifications And Features

- **PATH Stack Studio**: Drag-and-drop to prioritize search pathways with visual status dot indicators (Green checkmark denotes folders that exist; orange/red warning signals dead/broken folders).
- **Alias Studio**: Edit shortcuts, search triggering keywords, and easily toggle shortcuts to comment them out of files without deleting them.
- **Environment Variables**: Audit credentials, lock sensitive variables behind Touch ID authentication, and auto-mask secrets as bullets (`••••••••`).
- **Safety Restores & Backups**: Every write command creates an automated timestamped backup of the config file in standard Library folders prior to commits. Recover snapshots securely with 1-click.
- **Ultra-Light Footprint**: Operates entirely in memory with zero external frameworks, targeting less than 20MB of resident memory.

---

## Grabbing The DMG From Releases

Developers and end-users can download the pre-packaged `.dmg` file from our project's **GitHub Releases** portal (`https://github.com/AMFI-Disable/PathDeck/releases`):

1. Navigate to the **Releases** section of the repository.
2. Under the latest tag (e.g. `v1.0.1`), download the compiled `pathdeck-1.0.1.dmg` asset.
3. Verify the cryptographic SHA-256 checksum against GitHub Releases:
   ```bash
   shasum -a 256 pathdeck-1.0.1.dmg
   ```
4. Double-click the downloaded disk image to mount it, and drag `PathDeck.app` into your local `/Applications` folder.

---

## macOS Gatekeeper Clearance (Unnotarized Open-Source Build)

Because PathDeck is an open-source build provided without a paid Apple Developer ID certificate ($99/year), macOS Gatekeeper quarantines downloaded application bundles by default on first launch.

### Method 1: Stripping Extended Attributes (Terminal)

To clear the quarantine attribute via Terminal:

```bash
sudo xattr -r -c /Applications/PathDeck.app
```

*(For example, if testing directly from the workspace build folder)*:

```bash
xattr -cr ./PathDeck.app
```

### Method 2: System Settings Open Anyway (GUI)

Open **System Settings > Privacy & Security**, scroll down to the Security section, and click **Open Anyway**.

### Method 3: The Right-Click Open Sequence

1. Locate `PathDeck.app` inside Finder (or your `/Applications` directory).
2. Control-click (or right-click) the application icon and select **Open** from the shortcut context menu.
3. In the security confirmation sheet pop-up, click **Open** again to authorize launch.
4. macOS will register a security override, permitting direct launches henceforth.

---

## Automated Compilation And Build Pipeline
To compile and package the final release assets locally:

1. Run the build script in the project root:
   ```bash
   ./scripts/build.sh
   ```
2. The script compiles the package in production release mode (`-c release`), scaffolds standard bundle directories, injects `info.plist` (declaring bundle `com.amfi-disable.PathDeck` version `V1.0.1`), signs it locally using ad-hoc `codesign`, and packages the bundle into a compressed DMG disk image using `hdiutil`.
3. Locate the compiled outputs in the project root:
   - Standalone app: `./PathDeck.app`
   - Compressed installer: `./PathDeck.dmg`
