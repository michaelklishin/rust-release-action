#!/usr/bin/env nu

# Tests Windows binaries and MSI installers

use common.nu [error, output]
use test-common.nu [verify-checksum, get-version-output, check-version-in-output]
use download-release.nu [download-windows-artifacts]

def main [] {
    let download_from_release = ($env.DOWNLOAD_FROM_RELEASE? | default "false") == "true"
    let binary_name = $env.BINARY_NAME? | default ""
    let version = $env.VERSION? | default ""

    if $binary_name == "" {
        error "binary-name is required"
    }
    if $version == "" {
        error "version is required"
    }

    let artifacts = if $download_from_release {
        let downloaded = download-windows-artifacts $binary_name $version
        { binary: $downloaded.binary, msi: $downloaded.msi }
    } else {
        let binary_path = $env.BINARY_PATH? | default ""
        let msi_path = $env.MSI_PATH? | default ""
        let checksum_file = $env.CHECKSUM_FILE? | default ""
        let msi_checksum_file = $env.MSI_CHECKSUM_FILE? | default ""

        if $binary_path == "" and $msi_path == "" {
            error "binary-path or msi-path is required when download-from-release is false"
        }

        # Verify checksums if provided
        if $binary_path != "" and $checksum_file != "" {
            verify-checksum $binary_path $checksum_file
        }
        if $msi_path != "" and $msi_checksum_file != "" {
            verify-checksum $msi_path $msi_checksum_file
        }

        { binary: $binary_path, msi: $msi_path }
    }

    print $"(ansi green)Testing Windows artifacts(ansi reset)"
    print $"(ansi green)Expected version:(ansi reset) ($version)"

    if $artifacts.binary != "" {
        test-binary $artifacts.binary $version
    }

    if $artifacts.msi != "" {
        test-msi $artifacts.msi $binary_name $version
    }

    print $"(ansi green)All tests passed(ansi reset)"
    output "result" "success"
}

def test-binary [binary_path: string, version: string] {
    print $"(ansi green)Testing binary:(ansi reset) ($binary_path)"

    if not ($binary_path | path exists) {
        error $"binary not found: ($binary_path)"
    }

    print $"(ansi green)Running binary...(ansi reset)"
    let version_output = get-version-output $binary_path
    if not (check-version-in-output $version_output $version) {
        error $"version mismatch: expected ($version) in output: ($version_output)"
    }
    print $"  Version ($version) ✓"
}

def test-msi [msi_path: string, binary_name: string, version: string] {
    print $"(ansi green)Testing MSI installer:(ansi reset) ($msi_path)"

    if not ($msi_path | path exists) {
        error $"MSI not found: ($msi_path)"
    }

    # Use a predictable install directory for testing
    let user_profile = $env.USERPROFILE? | default "C:/Users/runneradmin"
    let install_dir = $"($user_profile)/($binary_name)-msi"

    install-msi $msi_path $install_dir
    verify-installed-binary $binary_name $version $install_dir
    uninstall-msi $msi_path
}

def install-msi [msi_path: string, install_dir: string] {
    print $"(ansi green)Installing MSI to:(ansi reset) ($install_dir)"
    # cargo-wix uses APPLICATIONFOLDER for the install directory
    let result = do { msiexec /i $msi_path /quiet /norestart $"APPLICATIONFOLDER=($install_dir)" } | complete
    if $result.exit_code != 0 {
        error $"failed to install MSI: ($result.stderr)"
    }
    print "  MSI installed ✓"
}

def verify-installed-binary [binary_name: string, expected_version: string, install_dir: string] {
    print $"(ansi green)Verifying installed binary...(ansi reset)"

    # cargo-wix installs binaries to the `bin/` subdirectory
    let possible_paths = [
        $"($install_dir)/($binary_name).exe"
        $"($install_dir)/bin/($binary_name).exe"
    ]

    mut bin_path = ""
    for path in $possible_paths {
        if ($path | path exists) {
            $bin_path = $path
            break
        }
    }

    if $bin_path == "" {
        print $"  Checked paths: ($possible_paths | str join ', ')"
        # List what's actually in the install directory for debugging
        if ($install_dir | path exists) {
            print $"  Contents of ($install_dir):"
            ls $install_dir | each { |f| print $"    ($f.name)" }
        } else {
            print $"  Install directory does not exist: ($install_dir)"
        }
        error "installed binary not found"
    }

    print $"  Found: ($bin_path)"
    let version_output = get-version-output $bin_path
    if not (check-version-in-output $version_output $expected_version) {
        error $"version mismatch: expected ($expected_version) in output: ($version_output)"
    }
    print $"  Version ($expected_version) ✓"
}

def uninstall-msi [msi_path: string] {
    print $"(ansi green)Uninstalling MSI...(ansi reset)"
    let result = do { msiexec /x $msi_path /quiet /norestart } | complete
    if $result.exit_code != 0 {
        error $"failed to uninstall MSI: ($result.stderr)"
    }
    print "  MSI uninstalled ✓"
}
