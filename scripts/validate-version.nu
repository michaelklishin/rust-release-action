#!/usr/bin/env nu

use common.nu [output]

def main [] {
    let tag = $env.TAG? | default ($env.GITHUB_REF_NAME? | default "")
    let expected = $env.EXPECTED_VERSION? | default ($env.NEXT_RELEASE_VERSION? | default "")

    if $tag == "" {
        print "error: TAG or GITHUB_REF_NAME environment variable is required"
        print "hint: set TAG to the git tag being released (e.g., v1.2.3)"
        exit 1
    }

    if $expected == "" {
        print "error: EXPECTED_VERSION or NEXT_RELEASE_VERSION environment variable is required"
        print "hint: set NEXT_RELEASE_VERSION in your repository's Actions variables"
        print "      Settings -> Secrets and variables -> Actions -> Variables"
        exit 1
    }

    if not ($tag | str starts-with "v") {
        print $"error: tag '($tag)' must start with 'v'"
        exit 1
    }

    let version = $tag | str substring 1..
    if $version != $expected {
        print "error: version mismatch"
        print $"  tag version: ($version)"
        print $"  expected:    ($expected)"
        print ""
        print "To fix this, either:"
        print $"  1. Update NEXT_RELEASE_VERSION to '($version)'"
        print $"  2. Push a new tag 'v($expected)'"
        exit 1
    }

    print $"Version validated: ($tag) matches ($expected)"
    output "version" $version
}
