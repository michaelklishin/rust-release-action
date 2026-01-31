# Changelog

## v0.7.0 (Jan 31, 2026)

### Initial Release

 * `extract-changelog` command for extracting version-specific release notes from CHANGELOG.md
 * `validate-version` command for ensuring git tags match expected versions
 * `get-version` command for reading version from Cargo.toml (supports workspace manifests)
 * `release-linux`, `release-macos`, `release-windows` build commands
 * Composite GitHub Action with Nu shell scripts
 * Cross-platform CI testing (Linux, macOS, Windows)
