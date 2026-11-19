export const siteConfig = {
  "title": "PathDeck",
  "repoUrl": "https://github.com/AMFI-Disable/PathDeck",
  "category": "macOS Native App",
  "accent": "#2EA3F2",
  "tagline": "Native SwiftUI developer studio for visually managing, reordering, and backing up shell PATHs, aliases, and environment variables.",
  "primaryCta": {
    "label": "Get Started",
    "href": "#quick-start"
  },
  "secondaryCta": {
    "label": "View on GitHub",
    "href": "https://github.com/AMFI-Disable/PathDeck"
  },
  "quickCmd": "git clone https://github.com/AMFI-Disable/PathDeck.git && cd PathDeck && open PathDeck.xcodeproj",
  "features": [
    {
      "title": "PATH Stack Studio",
      "desc": "Drag-and-drop to prioritize PATH entries with live green/orange disk validation indicators."
    },
    {
      "title": "Alias Studio",
      "desc": "Register, edit, or cleanly toggle shell aliases by commenting them out in ~/.zshrc without losing definitions."
    },
    {
      "title": "Touch ID Secret Masking",
      "desc": "Protect sensitive environment variables behind Touch ID biometrics with bullet masking in memory."
    },
    {
      "title": "Zero-Loss Backup Restores",
      "desc": "Automatically creates timestamped snapshots in Application Support before every config write."
    }
  ],
  "steps": [
    {
      "title": "Parse Shell Profiles",
      "desc": "Reads ~/.zshrc and ~/.bash_profile into structured PATH, alias, and export blocks without breaking custom scripts."
    },
    {
      "title": "Background Disk Validation",
      "desc": "Verifies directory existence off the main thread so the SwiftUI interface stays 120fps smooth."
    },
    {
      "title": "Snapshot & Commit",
      "desc": "Saves a timestamped backup before writing clean, deterministic shell exports back to disk."
    }
  ],
  "installCmds": [
    {
      "label": "Clone & Build in Xcode",
      "cmd": "git clone https://github.com/AMFI-Disable/PathDeck.git && cd PathDeck && swift build"
    },
    {
      "label": "Download Release DMG",
      "cmd": "open https://github.com/AMFI-Disable/PathDeck/releases"
    }
  ],
  "requirements": [
    "macOS 14.0+ (Sonoma / Sequoia)",
    "Swift 5.10+",
    "100% local, zero telemetry"
  ]
} as const;
