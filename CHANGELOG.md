# Changelog

All notable changes to PathDeck Studio are documented in this file. Versions follow semantic versioning with a `V` prefix.

## V1.0.1 — Final Standalone Release (2026-10-10)

The final maintenance release before PathDeck is folded into its parent application for integration. The in-app GitHub release checker remains fully operational; no further standalone releases are planned after this tag.

### Fixed
- **Version identity unified**: the canonical version now lives in a single `AppVersion` constant. The bundle (`info.plist`), sidebar label, and update checker all report `V1.0.1` — previously the bundle reported `V1.1.1` while the interface reported `V1.0.0`.
- **Deactivated aliases survive round-trips**: commented-out alias lines (`# alias gp="git push"`) now tokenize back as disabled alias entries instead of collapsing into plain comments, so toggling an alias off and saving no longer makes it vanish from Alias Studio.
- **PATH direction and comments preserved on save**: consolidating the PATH stack no longer silently rewrites append-style exports (`export PATH="$PATH:/dir"`) into prepends, and inline comments on path exports are kept.
- **Profile fallback implemented**: profile detection now honors `~/.bash_profile` when `~/.zshrc` is absent, matching the documented behavior, and defaults to `~/.zshrc` on fresh machines.
- **Atomic backup restoration**: restores now stage the snapshot beside the target and swap it in with an atomic replace, so an interrupted restore can no longer leave a truncated live `~/.zshrc`. Restoring onto a missing target now materializes the file instead of failing.
- **Honest memory diagnostics**: the dashboard memory statistic reports the process's real kernel-reported resident footprint instead of a hardcoded placeholder value.

### Changed
- CI release pipeline triggers on both `V*` and `v*` tags.

## V1.0.0 (2026-07-09)

Initial public release of PathDeck Studio.

- **PATH Stack Studio**: drag-and-drop PATH prioritization with background disk validation and status indicators.
- **Alias Studio**: searchable alias registry with comment-preserving deactivation (toggle = comment out, never delete).
- **Environment Variables**: Touch ID-gated secrets with in-memory bullet masking and automatic sensitive-key detection.
- **Safety Restores & Backups**: timestamped snapshots in Application Support before every write, with one-click restore.
- **Distribution**: ad-hoc codesigned `PathDeck.app` and compressed DMG built by `scripts/build.sh`, published automatically by CI on `V*` tags.
