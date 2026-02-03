#!/usr/bin/env nu

# Tests for common.nu functions

use std/assert
use common.nu [format-dependency-list, build-summary, get-cargo-info, copy-docs, copy-includes]

def main [] {
    test-format-dependency-list
    test-build-summary
    test-get-cargo-info
    test-copy-docs
    test-copy-includes
}

def test-format-dependency-list [] {
    # Empty input
    assert equal (format-dependency-list "depends" "") ""
    assert equal (format-dependency-list "depends" "   ") ""
    assert equal (format-dependency-list "depends" ", ,") ""

    # Single item
    let single = format-dependency-list "depends" "libc6"
    assert ($single | str starts-with "depends:\n")
    assert ($single | str contains "libc6")

    # Multiple items
    let multi = format-dependency-list "requires" "glibc, openssl, zlib"
    assert ($multi | str starts-with "requires:\n")
    assert ($multi | str contains "glibc")
    assert ($multi | str contains "openssl")
    assert ($multi | str contains "zlib")

    # Whitespace handling
    let spaced = format-dependency-list "depends" "  pkg1  ,  pkg2  "
    assert ($spaced | str contains "pkg1")
    assert ($spaced | str contains "pkg2")
    assert (not ($spaced | str contains "  pkg"))
}

def test-build-summary [] {
    let checksums = {sha256: "abc123", sha512: "def456", b2: "ghi789"}
    let result = build-summary "mybin" "1.2.3" "x86_64-unknown-linux-gnu" "mybin-1.2.3.tar.gz" "/path/to/artifact" $checksums

    let parsed = $result | from json
    assert equal $parsed.binary_name "mybin"
    assert equal $parsed.version "1.2.3"
    assert equal $parsed.target "x86_64-unknown-linux-gnu"
    assert equal $parsed.artifact "mybin-1.2.3.tar.gz"
    assert equal $parsed.artifact_path "/path/to/artifact"
    assert equal $parsed.sha256 "abc123"
    assert equal $parsed.sha512 "def456"
    assert equal $parsed.b2 "ghi789"
}

def test-get-cargo-info [] {
    let temp_dir = $"/tmp/test-cargo-info-(random uuid)"
    mkdir $temp_dir

    # Test simple Cargo.toml
    let cargo_toml = '[package]
name = "test-app"
version = "1.2.3"
'
    $cargo_toml | save $"($temp_dir)/Cargo.toml"

    $env.MANIFEST_PATH = $"($temp_dir)/Cargo.toml"
    let info = get-cargo-info
    assert equal $info.name "test-app"
    assert equal $info.version "1.2.3"

    # Test workspace root Cargo.toml (version at workspace level)
    let workspace_toml = '[workspace.package]
version = "4.5.6"

[package]
name = "workspace-app"
'
    $workspace_toml | save -f $"($temp_dir)/Cargo.toml"

    let workspace_info = get-cargo-info
    assert equal $workspace_info.name "workspace-app"
    assert equal $workspace_info.version "4.5.6"

    # Clean up
    hide-env MANIFEST_PATH
    rm -rf $temp_dir
}

def test-copy-docs [] {
    let original_dir = pwd
    let temp_src = $"/tmp/test-copy-docs-src-(random uuid)"
    let temp_dest = $"/tmp/test-copy-docs-dest-(random uuid)"
    mkdir $temp_src
    mkdir $temp_dest

    # Create test files in source
    cd $temp_src
    "MIT License content" | save LICENSE
    "Apache License content" | save LICENSE-APACHE
    "README content" | save README.md

    copy-docs $temp_dest

    # Verify files were copied
    assert ($"($temp_dest)/LICENSE" | path exists)
    assert ($"($temp_dest)/LICENSE-APACHE" | path exists)
    assert ($"($temp_dest)/README.md" | path exists)

    # Clean up
    cd $original_dir
    rm -rf $temp_src
    rm -rf $temp_dest
}

def test-copy-includes [] {
    let original_dir = pwd
    let temp_src = $"/tmp/test-copy-includes-src-(random uuid)"
    let temp_dest = $"/tmp/test-copy-includes-dest-(random uuid)"
    mkdir $temp_src
    mkdir $temp_dest

    # Create test files
    cd $temp_src
    "config content" | save config.toml
    "other content" | save other.txt
    mkdir subdir
    "nested content" | save subdir/nested.txt

    # Test with ARCHIVE_INCLUDE set
    $env.ARCHIVE_INCLUDE = "config.toml, other.txt"
    copy-includes $temp_dest

    assert ($"($temp_dest)/config.toml" | path exists)
    assert ($"($temp_dest)/other.txt" | path exists)

    # Clean up
    cd $original_dir
    hide-env ARCHIVE_INCLUDE
    rm -rf $temp_src
    rm -rf $temp_dest
}
