#!/bin/bash

set -euo pipefail

printf '%s\n' "$*" >>"${FXNK_TEST_NOTIFY_FILE:?}"
