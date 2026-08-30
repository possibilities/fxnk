#!/bin/bash

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
validator="$root/scripts/validate-full-ci-workflow.rb"

fail() {
    printf 'full-ci-workflow: %s\n' "$*" >&2
    exit 1
}

expect_reject() {
    local mode="$1" label="$2" output status
    set +e
    output=$("$validator" "$mode" 2>&1)
    status=$?
    set -e
    [ "$status" -ne 0 ] || fail "$label was accepted"
    [ -n "$output" ] || fail "$label rejection was not explained"
}

"$validator" hosted <<'YAML'
name: Full CI
on:
  workflow_dispatch:
  push:
    branches:
      - integration
concurrency:
  group: full-ci
  cancel-in-progress: true
jobs:
  noop: {}
YAML

"$validator" main <<'YAML'
on:
  workflow_dispatch:
  push:
    branches-ignore:
      - main
concurrency:
  group: full-ci-${{ github.ref }}
  cancel-in-progress: true
YAML

expect_reject hosted 'scalar on stanza' <<'YAML'
on: |
  workflow_dispatch:
  push:
    branches:
      - integration
concurrency:
  group: full-ci
  cancel-in-progress: true
YAML

expect_reject hosted 'scalar concurrency stanza' <<'YAML'
on:
  workflow_dispatch:
  push:
    branches:
      - integration
concurrency: |
  group: full-ci
  cancel-in-progress: true
YAML

expect_reject hosted 'quoted duplicate on key' <<'YAML'
on:
  workflow_dispatch:
  push:
    branches:
      - integration
concurrency:
  group: full-ci
  cancel-in-progress: true
jobs:
  noop: {}
"on": unsafe
YAML

expect_reject hosted 'quoted duplicate concurrency key' <<'YAML'
on:
  workflow_dispatch:
  push:
    branches:
      - integration
concurrency:
  group: full-ci
  cancel-in-progress: true
jobs:
  noop: {}
"concurrency": unsafe
YAML

printf 'Full CI workflow contract validation passed.\n'
