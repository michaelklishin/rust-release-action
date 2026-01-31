#!/usr/bin/env nu

use common.nu [get-cargo-info, output, copy-docs, ensure-lockfile, cargo-build, hr-line, error]

def main [] {
    let target = $env.TARGET? | default "aarch64-apple-darwin"
    let info = get-cargo-info
    let binary_name = $env.BINARY_NAME? | default $info.name
    let version = $info.version
    let create_archive = $env.ARCHIVE? | default "" | $in == "true"

    if $binary_name == "" {
        error "could not determine binary name"
    }
    if $version == "" {
        error "could not determine version"
    }

    print $"(ansi green)Building(ansi reset) ($binary_name) v($version) for ($target)"

    let release_dir = $"target/($target)/release"
    rm -rf $release_dir
    mkdir $release_dir

    ensure-lockfile
    rustup target add $target
    cargo-build $target $binary_name

    let src = $"($release_dir)/($binary_name)"
    if not ($src | path exists) {
        error $"binary not found: ($src)"
    }

    copy-docs $release_dir

    let artifact_base = $"($binary_name)-($version)-($target)"

    if $create_archive {
        # Create a tar.gz archive
        let artifact = $"($artifact_base).tar.gz"
        let artifact_path = $"($release_dir)/($artifact)"
        print $"(ansi green)Creating archive:(ansi reset) ($artifact)"
        tar -C $release_dir -czf $artifact_path $binary_name
        chmod +x $"($release_dir)/($binary_name)"

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $artifact_path
    } else {
        # Rename the binary
        let artifact = $artifact_base
        let artifact_path = $"($release_dir)/($artifact)"
        cp $src $artifact_path
        chmod +x $artifact_path

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $artifact_path
    }
}
