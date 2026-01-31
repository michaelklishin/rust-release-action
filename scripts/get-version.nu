#!/usr/bin/env nu

use common.nu [get-cargo-info, output]

def main [] {
    let manifest_path = $env.MANIFEST_PATH? | default "Cargo.toml"

    if not ($manifest_path | path exists) {
        print $"error: manifest not found: ($manifest_path)"
        exit 1
    }

    let info = get-cargo-info
    let version = $info.version

    if $version == "" {
        print "error: no version found in Cargo.toml"
        print "hint: ensure [package] or [workspace.package] has a version field"
        exit 1
    }

    if not ($version =~ '^\d+\.\d+\.\d+') {
        print $"error: invalid version format: ($version)"
        exit 1
    }

    print $version
    output "version" $version
}
