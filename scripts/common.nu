#!/usr/bin/env nu

# Reads Cargo.toml once and returns [name, version]
export def get-cargo-info []: nothing -> record<name: string, version: string> {
    let cargo = open Cargo.toml
    let name = $cargo | get -i package.name | default ""
    let version = $cargo | get -i package.version | default ($cargo | get -i workspace.package.version | default "")
    { name: $name, version: $version }
}

# Writes key=value to GITHUB_OUTPUT if available
export def output [key: string, value: string] {
    if ($env.GITHUB_OUTPUT? | is-not-empty) {
        $"($key)=($value)\n" | save --append $env.GITHUB_OUTPUT
    }
}

# Copies LICENSE-* and README.md to destination
export def copy-docs [dest: string] {
    glob LICENSE-* | each {|f| cp $f $dest }
    if ("README.md" | path exists) { cp README.md $dest }
}
