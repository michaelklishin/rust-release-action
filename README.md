# rust-release-action

An opinionated GitHub Action that automates release workflows for Rust projects using Nu shell scripts.

This is a conventions-based release process extracted from:

 * [rabbitmq/rabbitmqadmin-ng](https://github.com/rabbitmq/rabbitmqadmin-ng)
 * [michaelklishin/rabbitmq-lqt](https://github.com/michaelklishin/rabbitmq-lqt)
 * [michaelklishin/frm](https://github.com/michaelklishin/frm)

## Features

 * Parse `CHANGELOG.md` and extract release notes for a specific version
 * Validate git tags match expected versions via `NEXT_RELEASE_VERSION` variable
 * Support for semantic versioning including pre-release tags (alpha, beta, rc)
 * Extract version from `Cargo.toml` (supports workspace manifests)
 * Build and package binaries for Linux, macOS, and Windows
 * Generate SHA256, SHA512, and BLAKE2 checksums
 * JSON build summary for easy integration

## Conventions

This action expects:

 1. **Changelog format**: versions as `## v{version} ({date})` headers
 2. **Tag format**: tags prefixed with `v` (e.g., `v1.2.3`, `v1.0.0-beta.1`)
 3. **Version variable**: `NEXT_RELEASE_VERSION` GitHub Actions variable
 4. **Semantic versioning**: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]` format

## Usage

### Extract Changelog

```yaml
- uses: michaelklishin/rust-release-action@v0
  id: changelog
  with:
    command: extract-changelog
    version: '1.2.3'

# Outputs: version, release_notes_file, release_notes
```

### Validate Version

Tag and expected version are inferred from `GITHUB_REF_NAME` and `NEXT_RELEASE_VERSION`:

```yaml
- uses: michaelklishin/rust-release-action@v0
  id: validate
  with:
    command: validate-version
```

Or specify explicitly:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: validate-version
    tag: v1.2.3
    expected-version: '1.2.3'
```

### Get Version from Cargo.toml

```yaml
- uses: michaelklishin/rust-release-action@v0
  id: version
  with:
    command: get-version
```

### Build Release Binaries

```yaml
- uses: michaelklishin/rust-release-action@v0
  id: build
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu

# Outputs: version, binary_name, target, binary_path, artifact, artifact_path, sha256, summary
```

### Workspace Builds

For Cargo workspaces, specify the package name:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu
    package: my-cli-bin
    binary-name: my-cli
```

### Static Builds (musl)

For musl targets, static linking is enabled automatically. Use `no-default-features` to disable features that require dynamic linking (e.g., native-tls):

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-linux
    target: x86_64-unknown-linux-musl
    no-default-features: 'true'
```

### Enable Cargo Features

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu
    features: 'feature1,feature2'
```

### Archive Artifacts

Create .tar.gz archives on Linux/macOS or .zip on Windows:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu
    archive: 'true'
```

### Include Additional Files

Include extra files in the archive:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu
    archive: 'true'
    include: 'config/*.toml,docs/*.md'
```

### Generate Checksums

Generate multiple checksum types (default is sha256):

```yaml
- uses: michaelklishin/rust-release-action@v0
  id: build
  with:
    command: release-linux
    target: x86_64-unknown-linux-gnu
    checksum: 'sha256,sha512'

# Use the checksum in later steps
- run: echo "SHA256: ${{ steps.build.outputs.sha256 }}"
```

### Windows MSI Installer

Build a Windows MSI installer using cargo-wix:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: release-windows-msi
    target: x86_64-pc-windows-msvc
```

This requires a `wix/main.wxs` file in your project. See [cargo-wix documentation](https://github.com/volks73/cargo-wix) for setup.

### Monorepo Support

Use `working-directory` for projects in subdirectories:

```yaml
- uses: michaelklishin/rust-release-action@v0
  with:
    command: get-version
    working-directory: crates/my-cli
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `command` | Command to run (required) | - |
| `version` | Version to extract | - |
| `changelog` | Path to CHANGELOG.md | `CHANGELOG.md` |
| `output` | Output file for release notes | `release_notes.md` |
| `tag` | Git tag for validation | `GITHUB_REF_NAME` |
| `expected-version` | Expected version | `NEXT_RELEASE_VERSION` |
| `manifest` | Path to Cargo.toml | `Cargo.toml` |
| `target` | Rust target triple | platform default |
| `binary-name` | Binary name | package name |
| `package` | Cargo package name for workspaces | - |
| `no-default-features` | Build with --no-default-features | `false` |
| `features` | Comma-separated Cargo features to enable | - |
| `target-rustflags` | Extra RUSTFLAGS for the build | - |
| `archive` | Create archive (.tar.gz on Linux/macOS, .zip on Windows) | `false` |
| `locked` | Build with --locked for reproducible builds | `false` |
| `include` | Comma-separated glob patterns for additional files | - |
| `checksum` | Checksum algorithms (sha256, sha512, b2) | `sha256` |
| `profile` | Cargo build profile | `release` |
| `dry-run` | Build without uploading (for testing) | `false` |
| `working-directory` | Working directory | `.` |

## Outputs

| Output | Description |
|--------|-------------|
| `version` | Version from get-version, validate-version, or release commands |
| `release_notes_file` | Path to release notes file |
| `release_notes` | Release notes content |
| `artifact` | Artifact filename |
| `artifact_path` | Full path to artifact |
| `binary_name` | Binary name that was built |
| `binary_path` | Path to the raw binary (before archiving) |
| `target` | Target triple used for the build |
| `sha256` | SHA256 checksum of the artifact |
| `sha512` | SHA512 checksum of the artifact |
| `b2` | BLAKE2 checksum of the artifact |
| `summary` | JSON summary of the build |

## Complete Workflow Example

```yaml
name: Release

on:
  workflow_dispatch:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+*'

permissions:
  contents: write

concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

jobs:
  validate:
    runs-on: ubuntu-22.04
    timeout-minutes: 5
    outputs:
      version: ${{ steps.validate.outputs.version }}
    steps:
      # v4.2.2
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - uses: michaelklishin/rust-release-action@v0
        id: validate
        with:
          command: validate-version

  build:
    needs: validate
    timeout-minutes: 30
    strategy:
      fail-fast: false
      matrix:
        include:
          - target: x86_64-unknown-linux-gnu
            os: ubuntu-22.04
            command: release-linux
          - target: aarch64-unknown-linux-gnu
            os: ubuntu-24.04-arm
            command: release-linux
          - target: x86_64-unknown-linux-musl
            os: ubuntu-22.04
            command: release-linux
          - target: aarch64-apple-darwin
            os: macos-14
            command: release-macos
          - target: x86_64-pc-windows-msvc
            os: windows-2022
            command: release-windows
          - target: aarch64-pc-windows-msvc
            os: windows-11-arm
            command: release-windows
    runs-on: ${{ matrix.os }}
    steps:
      # v4.2.2
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - name: Setup Rust
        run: |
          rustup toolchain install stable --profile minimal
          rustup default stable

      # v2.7.8
      - uses: Swatinem/rust-cache@9d47c6ad4b02e050fd481d890b2ea34778fd09d6
        with:
          key: ${{ matrix.target }}

      - uses: michaelklishin/rust-release-action@v0
        id: build
        with:
          command: ${{ matrix.command }}
          target: ${{ matrix.target }}
          locked: 'true'

      # v4.6.2
      - uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
        with:
          name: ${{ matrix.target }}
          path: target/${{ matrix.target }}/release/
          retention-days: 2

  release:
    needs: [validate, build]
    runs-on: ubuntu-22.04
    timeout-minutes: 10
    steps:
      # v4.2.2
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

      - uses: michaelklishin/rust-release-action@v0
        with:
          command: extract-changelog
          version: ${{ needs.validate.outputs.version }}

      # v4.3.0
      - uses: actions/download-artifact@d3f86a106a0bac45b974a628896c90dbdf5c8093
        with:
          path: artifacts

      - name: Collect release files
        run: |
          mkdir -p release
          find artifacts -type f -name '*-${{ needs.validate.outputs.version }}-*' -exec cp {} release/ \;

      # v2.2.2
      - uses: softprops/action-gh-release@da05d552573ad5aba039eaac05058a918a7bf631
        with:
          tag_name: v${{ needs.validate.outputs.version }}
          name: v${{ needs.validate.outputs.version }}
          body_path: release_notes.md
          files: release/*
```

## Best Practices

 * Actions pinned to commit SHAs
 * Minimal token permissions
 * Uses `Swatinem/rust-cache` for faster builds
 * `--locked` flag for reproducible builds
 * Specific runner versions (as opposed to `*-latest`)
 * Timeouts on all jobs
 * Concurrency settings to prevent duplicate runs

## License

Licensed under either of:

 * Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE))
 * MIT license ([LICENSE-MIT](LICENSE-MIT))
