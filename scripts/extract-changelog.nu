#!/usr/bin/env nu

use common.nu [output]

def main [] {
    let version = $env.VERSION? | default ""
    if $version == "" {
        print "error: VERSION environment variable is required"
        exit 1
    }

    let changelog_path = $env.CHANGELOG_PATH? | default "CHANGELOG.md"
    let output_path = $env.OUTPUT_PATH? | default "release_notes.md"

    if not ($changelog_path | path exists) {
        print $"error: changelog not found: ($changelog_path)"
        exit 1
    }

    let content = open $changelog_path | lines
    let version_header = $"## v($version)"
    let alt_header = $"## ($version)"

    let start_idx = $content | enumerate | where {|row|
        ($row.item | str starts-with $version_header) or ($row.item | str starts-with $alt_header)
    } | get index | first

    if ($start_idx | is-empty) {
        print $"error: version ($version) not found in changelog"
        exit 1
    }

    let remaining = $content | skip ($start_idx + 1)
    let end_offset = $remaining | enumerate | where {|row|
        $row.item =~ '^## v?\d+\.\d+\.\d+'
    } | get index | first

    let notes = if ($end_offset | is-empty) {
        $remaining | str join "\n" | str trim
    } else {
        $remaining | take $end_offset | str join "\n" | str trim
    }

    if $notes == "" {
        print $"error: no content found for version ($version)"
        exit 1
    }

    $notes | save -f $output_path
    print $"Extracted release notes for v($version) to ($output_path)"
    output "release_notes_file" $output_path
}
