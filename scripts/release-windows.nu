#!/usr/bin/env nu

use common.nu [get-cargo-info, output, copy-docs, ensure-lockfile, cargo-build, hr-line, error]

def main [] {
    let target = $env.TARGET? | default "x86_64-pc-windows-msvc"
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

    let src = $"($release_dir)/($binary_name).exe"
    if not ($src | path exists) {
        error $"binary not found: ($src)"
    }

    copy-docs $release_dir

    let artifact_base = $"($binary_name)-($version)-($target)"

    if $create_archive {
        # Create a zip archive using 7z (available on Windows runners)
        let artifact = $"($artifact_base).zip"
        let artifact_path = $"($release_dir)/($artifact)"
        print $"(ansi green)Creating archive:(ansi reset) ($artifact)"
        cd $release_dir
        7z a $artifact $"($binary_name).exe"

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        # Normalise path separators for GitHub Actions
        let normalised_path = $artifact_path | str replace --all '\' '/'
        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $normalised_path
    } else {
        # Rename the binary
        let artifact = $"($artifact_base).exe"
        let artifact_path = $"($release_dir)/($artifact)"
        cp $src $artifact_path

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $artifact_path
    }
}
