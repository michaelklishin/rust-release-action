# Changelog

## v0.8.0 (Jan 31, 2026)

### Enhancements

 * Add `package` input for Cargo workspace builds
 * Add `no-default-features` input for static/musl builds
 * Add `target-rustflags` input for custom build flags
 * Automatic static linking for musl targets (`-C target-feature=+crt-static`)
 * Add Fedora support for cross-compilation
 * Add `armv7-unknown-linux-gnueabihf` target support
 * Generate `Cargo.lock` if missing
 * Refactor build logic into shared `cargo-build` function

## v0.7.0 (Jan 31, 2026)

### Initial Release

 * `extract-changelog` command for extracting version-specific release notes from CHANGELOG.md
 * `validate-version` command for ensuring git tags match expected versions
 * `get-version` command for reading version from Cargo.toml (supports workspace manifests)
 * `release-linux`, `release-macos`, `release-windows` build commands
 * Composite GitHub Action with Nu shell scripts
 * Cross-platform CI testing (Linux, macOS, Windows)
