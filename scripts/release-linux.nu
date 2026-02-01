#!/usr/bin/env nu

use common.nu [get-cargo-info, output, output-multiline, copy-docs, copy-includes, ensure-lockfile, cargo-build, hr-line, error, check-rust-toolchain, generate-checksums, build-summary]

def main [] {
    check-rust-toolchain

    let target = $env.TARGET? | default "x86_64-unknown-linux-gnu"
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
    install-dependencies $target
    cargo-build $target $binary_name

    let binary_path = $"($release_dir)/($binary_name)"
    if not ($binary_path | path exists) {
        error $"binary not found: ($binary_path)"
    }

    copy-docs $release_dir
    copy-includes $release_dir

    let artifact_base = $"($binary_name)-($version)-($target)"

    output "version" $version
    output "binary_name" $binary_name
    output "target" $target
    output "binary_path" $binary_path

    if $create_archive {
        let artifact = $"($artifact_base).tar.gz"
        let artifact_path = $"($release_dir)/($artifact)"
        print $"(ansi green)Creating archive:(ansi reset) ($artifact)"
        tar -C $release_dir -czf $artifact_path $binary_name
        chmod +x $binary_path

        let checksums = generate-checksums $artifact_path

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $artifact_path
        output "sha256" $checksums.sha256
        output "sha512" $checksums.sha512
        output "b2" $checksums.b2

        let summary = build-summary $binary_name $version $target $artifact $artifact_path $checksums
        output-multiline "summary" $summary
    } else {
        let artifact = $artifact_base
        let artifact_path = $"($release_dir)/($artifact)"
        cp $binary_path $artifact_path
        chmod +x $artifact_path

        let checksums = generate-checksums $artifact_path

        print $"(char nl)(ansi green)Build artifacts:(ansi reset)"
        hr-line
        ls $release_dir | print

        print $"(ansi green)Created:(ansi reset) ($artifact)"
        output "artifact" $artifact
        output "artifact_path" $artifact_path
        output "sha256" $checksums.sha256
        output "sha512" $checksums.sha512
        output "b2" $checksums.b2

        let summary = build-summary $binary_name $version $target $artifact $artifact_path $checksums
        output-multiline "summary" $summary
    }
}

def install-dependencies [target: string] {
    let is_ubuntu = (which apt-get | is-not-empty)
    let is_fedora = (which dnf | is-not-empty)

    if $target =~ "musl" {
        if $is_ubuntu {
            sudo apt-get update -qq
            sudo apt-get install -y -qq musl-tools
        }
    } else if $target == "aarch64-unknown-linux-gnu" {
        let arch = (^uname -m | str trim)
        if $arch != "aarch64" {
            if $is_ubuntu {
                sudo apt-get update -qq
                sudo apt-get install -y -qq gcc-aarch64-linux-gnu
            } else if $is_fedora {
                sudo dnf install -y gcc-aarch64-linux-gnu
            }
            $env.CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "aarch64-linux-gnu-gcc"
        }
    } else if $target == "armv7-unknown-linux-gnueabihf" {
        if $is_ubuntu {
            sudo apt-get update -qq
            sudo apt-get install -y -qq pkg-config gcc-arm-linux-gnueabihf
        } else if $is_fedora {
            sudo dnf install -y pkg-config gcc-arm-linux-gnueabihf
        }
        $env.CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER = "arm-linux-gnueabihf-gcc"
    }

    rustup target add $target
}
