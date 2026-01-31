#!/usr/bin/env nu

use common.nu [get-cargo-info, output, copy-docs]

def main [] {
    let target = $env.TARGET? | default "x86_64-unknown-linux-gnu"
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

    if $target =~ "musl" {
        if (which apt-get | is-not-empty) {
            sudo apt-get update -qq
            sudo apt-get install -y -qq musl-tools
        }
    } else if $target =~ "aarch64.*linux" and (^uname -m | str trim) != "aarch64" {
        if (which apt-get | is-not-empty) {
            sudo apt-get update -qq
            sudo apt-get install -y -qq gcc-aarch64-linux-gnu
        }
        $env.CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-linux-gnu-gcc"
    }

    rustup target add $target
    cargo build --release --locked --target $target -q

    let src = $"($release_dir)/($binary_name)"
    if not ($src | path exists) {
        print $"error: binary not found: ($src)"
        exit 1
    }

    let artifact = $"($binary_name)-($version)-($target)"
    let artifact_path = $"($release_dir)/($artifact)"
    cp $src $artifact_path
    chmod +x $artifact_path
    copy-docs $release_dir

    print $"Created: ($artifact)"
    output "artifact" $artifact
    output "artifact_path" $artifact_path
}
