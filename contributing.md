# Contributing To PathDeck

[Report A Bug](https://github.com/AMFI-Disable/PathDeck/issues/new?title=%5BBUG%5D+&body=%23%23+Environment+%2F+%E8%BF%90%E8%A1%8C%E7%8E%AF%E5%A2%83%0A%0A%23%23+Steps+To+Reproduce+%2F+%E5%A4%8D%E7%8E%B0%E6%AD%A5%E9%AA%A4%0A%0A%23%23+Expected+And+Actual+Results+%2F+%E9%A2%84%E6%9C%9F%E4%B8%8E%E5%AE%9E%E9%99%85%E7%BB%93%E6%9E%9C%0A%0A) · [Request A Feature](https://github.com/AMFI-Disable/PathDeck/issues/new?title=%5BFEATURE%5D+&body=%23%23+User+Need+%2F+%E4%BD%BF%E7%94%A8%E9%9C%80%E6%B1%82%0A%0A%23%23+Proposed+Change+%2F+%E6%94%B9%E8%BF%9B%E6%96%B9%E6%A1%88%0A%0A%23%23+Acceptance+Criteria+%2F+%E9%AA%8C%E6%94%B6%E6%9D%A1%E4%BB%B6%0A%0A)

[中文贡献指南](contributing.zh-cn.md)

Thank you for your interest in contributing to PathDeck! We welcome community contributions to help improve this visual macOS developer studio.

---

## How To Contribute

### 1. Reporting Bugs

- Please search existing issues to see if the bug has already been reported.
- If not, create a new bug report using our standard bug template.

### 2. Suggesting Enhancements

- Open a feature request detailing your proposed enhancement and rationale.

### 3. Code Contributions

- Fork the repository and create your feature branches off the `main` branch.
- Maintain our strict **all-lowercase file naming standard** for all files inside the repository (except for the final output `.app` and `.dmg`).
- Write accompanying unit tests under `tests/pathdecktests/` for any parser or backup manager updates.
- Keep the operational memory footprint under 20MB.
- Submit a Pull Request.

---

## Code Style & Rules

- **Strict File Naming**: Every file and folder inside the repository must be in lowercase.
- **Pure Swift**: No third-party packages or dependencies.
- **Safety First**: Never modify configuration files without executing an automated backup snapshot first.
