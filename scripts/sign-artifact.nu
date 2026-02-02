#!/usr/bin/env nu

use common.nu [output, hr-line, error]

def main [] {
    let cosign_path = get-cosign-path

    let artifact_path = $env.ARTIFACT_PATH? | default ""
    if $artifact_path == "" {
        error "ARTIFACT_PATH is required"
    }

    if not ($artifact_path | path exists) {
        error $"artifact not found: ($artifact_path)"
    }

    print $"(ansi green)Signing artifact:(ansi reset) ($artifact_path)"

    let sig_path = $"($artifact_path).sig"
    let cert_path = $"($artifact_path).pem"
    let bundle_path = $"($artifact_path).sigstore.json"

    # Build cosign args - cosign 3.x auto-detects GitHub Actions environment
    let args = [
        "sign-blob" "--yes"
        "--output-signature" $sig_path
        "--output-certificate" $cert_path
        "--bundle" $bundle_path
        $artifact_path
    ]

    let result = do { ^$cosign_path ...$args } | complete
    if $result.exit_code != 0 {
        print $"(ansi red)cosign output:(ansi reset)"
        print $result.stderr
        error "cosign signing failed"
    }

    print $"(char nl)(ansi green)Signature files:(ansi reset)"
    hr-line

    if ($sig_path | path exists) {
        print $"(ansi green)Signature:(ansi reset) ($sig_path)"
        output "signature_path" $sig_path
    }

    if ($cert_path | path exists) {
        print $"(ansi green)Certificate:(ansi reset) ($cert_path)"
        output "certificate_path" $cert_path
    }

    if ($bundle_path | path exists) {
        print $"(ansi green)Bundle:(ansi reset) ($bundle_path)"
        output "bundle_path" $bundle_path
    }

    output "artifact_path" $artifact_path
}

# Gets cosign path, installing if missing
def get-cosign-path []: nothing -> string {
    let existing = which cosign | get -i 0.path
    if $existing != null {
        return $existing
    }

    print $"(ansi yellow)cosign not found, installing...(ansi reset)"
    let cosign_version = "3.0.4"
    let is_windows = (sys host | get name) == "Windows"

    if $is_windows {
        let url = $"https://github.com/sigstore/cosign/releases/download/v($cosign_version)/cosign-windows-amd64.exe"
        let dest_path = ($env.USERPROFILE | path join ".local" "bin" "cosign.exe")
        mkdir ($dest_path | path dirname)
        http get $url | save -f $dest_path
        $dest_path
    } else {
        let arch = match (^uname -m | str trim) {
            "arm64" | "aarch64" => "arm64"
            _ => "amd64"
        }
        let os = match (^uname -s | str trim | str downcase) {
            "darwin" => "darwin"
            _ => "linux"
        }
        let url = $"https://github.com/sigstore/cosign/releases/download/v($cosign_version)/cosign-($os)-($arch)"
        http get $url | save -f /tmp/cosign
        chmod +x /tmp/cosign
        if (which sudo | is-not-empty) {
            sudo mv /tmp/cosign /usr/local/bin/cosign
        } else {
            mv /tmp/cosign /usr/local/bin/cosign
        }
        "/usr/local/bin/cosign"
    }
}
