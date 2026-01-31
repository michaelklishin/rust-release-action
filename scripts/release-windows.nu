#!/usr/bin/env nu

use common.nu [get-cargo-info, output, copy-docs]

def main [] {
    let target = $env.TARGET? | default "x86_64-pc-windows-msvc"
    let info = get-cargo-info
    let binary_name = $env.BINARY_NAME? | default $info.name
    let version = $info.version

    if $binary_name == "" {
        print "error: could not determine binary name"
        exit 1
    }
    if $version == "" {
        print "error: could not determine version"
        exit 1
    }

    print $"Building ($binary_name) v($version) for ($target)"

    let release_dir = $"target/($target)/release"
    mkdir $release_dir

    rustup target add $target
    cargo build --release --locked --target $target -q

    let src = $"($release_dir)/($binary_name).exe"
    if not ($src | path exists) {
        print $"error: binary not found: ($src)"
        exit 1
    }

    let artifact = $"($binary_name)-($version)-($target).exe"
    let artifact_path = $"($release_dir)/($artifact)"
    cp $src $artifact_path
    copy-docs $release_dir

    print $"Created: ($artifact)"
    output "artifact" $artifact
    output "artifact_path" $artifact_path
}
