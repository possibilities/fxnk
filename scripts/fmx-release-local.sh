#!/usr/bin/env bash

set -euo pipefail

repo="possibilities/fx"
zig_version="0.16.0"
vercel_version="59.9.1"

usage() {
    cat <<'EOF'
usage:
  scripts/fmx-release-local.sh build --worktree PATH --output DIR (--run-id ID | --linux-dir DIR)
  scripts/fmx-release-local.sh verify --worktree PATH --output DIR
  scripts/fmx-release-local.sh publish --worktree PATH --output DIR [--run-id ID --cancel-run]

Builds the two macOS fmx-fx archives serially on an Apple-silicon Mac,
combines them with trusted Linux artifacts, verifies the complete release set,
and can publish it through the same Vercel Blob contract as Fx's release
workflow. The worktree must be clean at the published Integration SHA.

--run-id downloads successful Linux artifacts from that exact GitHub Actions
run. --linux-dir accepts the eight files built on trusted native Linux hosts.
Publishing refuses an active run unless --cancel-run names the same run, so a
hosted publisher cannot race the local publisher on immutable Blob paths.
EOF
}

fail() {
    printf 'fmx Fx local release: %s\n' "$*" >&2
    exit 1
}

command_name="${1:-}"
case "$command_name" in
    build|verify|publish) shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

worktree=""
output=""
run_id=""
linux_dir=""
cancel_run=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --worktree)
            [ "$#" -ge 2 ] || fail '--worktree needs a path'
            worktree="$2"
            shift 2
            ;;
        --output)
            [ "$#" -ge 2 ] || fail '--output needs a directory'
            output="$2"
            shift 2
            ;;
        --run-id)
            [ "$#" -ge 2 ] || fail '--run-id needs an Actions run id'
            run_id="$2"
            shift 2
            ;;
        --linux-dir)
            [ "$#" -ge 2 ] || fail '--linux-dir needs a directory'
            linux_dir="$2"
            shift 2
            ;;
        --cancel-run)
            cancel_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *) fail "unknown argument: $1" ;;
    esac
done

[ -n "$worktree" ] || fail '--worktree is required'
[ -n "$output" ] || fail '--output is required'
[ -d "$worktree" ] || fail "worktree is not a directory: $worktree"
worktree=$(cd "$worktree" && pwd -P)
mkdir -p "$output"
output=$(cd "$output" && pwd -P)

for required in bash curl file gh git gzip jq npx shasum tar xz; do
    command -v "$required" >/dev/null 2>&1 \
        || fail "required command not found: $required"
done

sha=$(git -C "$worktree" rev-parse HEAD)
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || fail 'worktree HEAD is not a full commit'
if ! git -C "$worktree" diff --quiet \
    || ! git -C "$worktree" diff --cached --quiet; then
    fail 'worktree must be clean'
fi
remote_sha=$(gh api "repos/$repo/branches/integration" --jq .commit.sha)
[ "$sha" = "$remote_sha" ] \
    || fail "worktree HEAD is $sha but $repo:integration is $remote_sha"

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/fxnk"
lock_dir="$state_root/fmx-release-local.lock"
mkdir -p "$state_root"
if ! mkdir "$lock_dir" 2>/dev/null; then
    holder=$(sed -n '1p' "$lock_dir/pid" 2>/dev/null || true)
    if [[ "$holder" =~ ^[0-9]+$ ]] && kill -0 "$holder" 2>/dev/null; then
        fail "another local release is running as pid $holder"
    fi
    rmdir "$lock_dir" 2>/dev/null \
        || fail "stale release lock needs inspection: $lock_dir"
    mkdir "$lock_dir"
fi
printf '%s\n' "$$" > "$lock_dir/pid"

work_dir=$(mktemp -d "${TMPDIR:-/tmp}/fxnk-fmx-release.XXXXXX")
cleanup() {
    rm -rf "$work_dir"
    rm -f "$lock_dir/pid"
    rmdir "$lock_dir" 2>/dev/null || true
}
trap cleanup EXIT

curl_get() {
    curl --fail --silent --show-error --location --retry 3 \
        --connect-timeout 10 "$@"
}

sha256_file() {
    shasum -a 256 "$1" | awk '{ print $1 }'
}

verify_run() {
    [ -n "$run_id" ] || fail '--run-id is required for this operation'
    [[ "$run_id" =~ ^[0-9]+$ ]] || fail "invalid run id: $run_id"
    run_json=$(gh run view "$run_id" --repo "$repo" \
        --json headSha,workflowName,status,conclusion,jobs)
    run_sha=$(jq -r .headSha <<<"$run_json")
    workflow=$(jq -r .workflowName <<<"$run_json")
    [ "$run_sha" = "$sha" ] \
        || fail "run $run_id is for $run_sha rather than $sha"
    [ "$workflow" = 'Release fmx Fx binary' ] \
        || fail "run $run_id is the wrong workflow: $workflow"
}

verify_release_set() {
    local platform extension archive expected actual manifest_dir probe
    local expected_manifest
    expected_manifest=$'fmx-fx\nLICENSE\nTHIRD_PARTY_NOTICES.md\n'
    [ "$(find "$output" -maxdepth 1 -type f | wc -l | tr -d ' ')" = 16 ] \
        || fail "$output does not contain exactly 16 release files"
    for platform in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64; do
        for extension in tar.xz tar.gz; do
            archive="fmx-fx-$platform.$extension"
            [ -f "$output/$archive" ] || fail "missing $archive"
            [ -f "$output/$archive.sha256" ] || fail "missing $archive.sha256"
            expected=$(awk 'NR == 1 { print $1 }' "$output/$archive.sha256")
            [[ "$expected" =~ ^[0-9a-f]{64}$ ]] \
                || fail "invalid checksum file: $archive.sha256"
            actual=$(sha256_file "$output/$archive")
            [ "$actual" = "$expected" ] || fail "checksum mismatch: $archive"
            [ "$(tar -tf "$output/$archive")"$'\n' = "$expected_manifest" ] \
                || fail "unexpected archive manifest: $archive"
        done
    done

    [ "$(uname -s)" = Darwin ] || return 0
    manifest_dir="$work_dir/verify"
    mkdir -p "$manifest_dir/arm64" "$manifest_dir/x86_64"
    tar -xJf "$output/fmx-fx-macos-aarch64.tar.xz" -C "$manifest_dir/arm64"
    tar -xJf "$output/fmx-fx-macos-x86_64.tar.xz" -C "$manifest_dir/x86_64"
    file "$manifest_dir/arm64/fmx-fx" | grep -F 'Mach-O 64-bit executable arm64' >/dev/null \
        || fail 'macos-aarch64 archive has the wrong binary architecture'
    file "$manifest_dir/x86_64/fmx-fx" | grep -F 'Mach-O 64-bit executable x86_64' >/dev/null \
        || fail 'macos-x86_64 archive has the wrong binary architecture'
    codesign --verify "$manifest_dir/arm64/fmx-fx"
    codesign --verify "$manifest_dir/x86_64/fmx-fx"
    probe=$("$manifest_dir/arm64/fmx-fx" --fxnk-version)
    [ "$probe" = 'fxnk 0.5.0 (fx 0.0.6)' ] \
        || fail "unexpected arm64 fork identity: $probe"
    probe=$(/usr/bin/arch -x86_64 "$manifest_dir/x86_64/fmx-fx" --fxnk-version)
    [ "$probe" = 'fxnk 0.5.0 (fx 0.0.6)' ] \
        || fail "unexpected x86_64 fork identity: $probe"
}

build_release_set() {
    [ "$(uname -s)" = Darwin ] && [ "$(uname -m)" = arm64 ] \
        || fail 'local macOS release assembly requires an Apple-silicon Mac'
    /usr/bin/arch -x86_64 /usr/bin/uname -m 2>/dev/null | grep -Fx x86_64 >/dev/null \
        || fail 'Rosetta 2 is required for the Intel macOS archive'
    [ -x "$worktree/scripts/build-fmx-release.sh" ] \
        || fail 'Fx worktree has no executable scripts/build-fmx-release.sh'
    if [ -n "$run_id" ] && [ -n "$linux_dir" ]; then
        fail 'use either --run-id or --linux-dir, not both'
    fi
    if [ -z "$run_id" ] && [ -z "$linux_dir" ]; then
        fail 'build requires --run-id or --linux-dir'
    fi
    if find "$output" -mindepth 1 -maxdepth 1 | grep -q .; then
        fail "build output must start empty: $output"
    fi

    mkdir -p "$work_dir/macos-aarch64" "$work_dir/macos-x86_64"
    (
        cd "$worktree"
        FMX_FX_RELEASE_DIR="$work_dir/macos-aarch64" \
            scripts/build-fmx-release.sh macos-aarch64
    )

    index_json="$work_dir/zig-index.json"
    curl_get https://ziglang.org/download/index.json -o "$index_json"
    zig_url=$(jq -er --arg version "$zig_version" \
        '.[$version]."x86_64-macos".tarball' "$index_json")
    zig_checksum=$(jq -er --arg version "$zig_version" \
        '.[$version]."x86_64-macos".shasum' "$index_json")
    zig_archive="$work_dir/zig-x86_64-macos.tar.xz"
    curl_get "$zig_url" -o "$zig_archive"
    [ "$(sha256_file "$zig_archive")" = "$zig_checksum" ] \
        || fail 'downloaded Intel Zig archive failed its published checksum'
    mkdir -p "$work_dir/zig"
    tar -xJf "$zig_archive" -C "$work_dir/zig"
    zig_bin=$(find "$work_dir/zig" -mindepth 2 -maxdepth 2 -type f -name zig -perm -111)
    [ -n "$zig_bin" ] && [ "$(file "$zig_bin")" = "$zig_bin: Mach-O 64-bit executable x86_64" ] \
        || fail 'downloaded Intel Zig toolchain has the wrong architecture'
    [ "$(/usr/bin/arch -x86_64 "$zig_bin" version)" = "$zig_version" ] \
        || fail 'downloaded Intel Zig toolchain has the wrong version'
    zig_dir=$(dirname "$zig_bin")
    (
        cd "$worktree"
        /usr/bin/arch -x86_64 /usr/bin/env \
            PATH="$zig_dir:$PATH" \
            FMX_FX_RELEASE_DIR="$work_dir/macos-x86_64" \
            /bin/bash scripts/build-fmx-release.sh macos-x86_64
    )

    linux_source="$linux_dir"
    if [ -n "$run_id" ]; then
        verify_run
        for platform in linux-x86_64 linux-aarch64; do
            job_state=$(jq -r --arg name "Build $platform" \
                '.jobs[] | select(.name == $name) | [.status,.conclusion] | @tsv' \
                <<<"$run_json")
            [ "$job_state" = $'completed\tsuccess' ] \
                || fail "run $run_id has no successful Build $platform job"
        done
        linux_source="$work_dir/linux"
        mkdir -p "$linux_source"
        gh run download "$run_id" --repo "$repo" \
            --name fmx-fx-linux-x86_64 --dir "$linux_source"
        gh run download "$run_id" --repo "$repo" \
            --name fmx-fx-linux-aarch64 --dir "$linux_source"
    fi
    [ -d "$linux_source" ] || fail "Linux artifact directory not found: $linux_source"
    cp "$linux_source"/fmx-fx-linux-* "$output/"
    cp "$work_dir/macos-aarch64"/fmx-fx-macos-aarch64.* "$output/"
    cp "$work_dir/macos-x86_64"/fmx-fx-macos-x86_64.* "$output/"
    verify_release_set
    printf 'Built and verified fmx Fx %s in %s\n' "$sha" "$output"
}

cancel_active_run() {
    [ -n "$run_id" ] || return 0
    verify_run
    run_state=$(jq -r .status <<<"$run_json")
    case "$run_state" in
        completed) return 0 ;;
        queued|in_progress|pending|waiting)
            [ "$cancel_run" -eq 1 ] \
                || fail "run $run_id is active; pass --cancel-run before local publication"
            gh run cancel "$run_id" --repo "$repo"
            for _ in $(seq 1 60); do
                run_state=$(gh run view "$run_id" --repo "$repo" --json status --jq .status)
                [ "$run_state" = completed ] && return 0
                sleep 2
            done
            fail "run $run_id did not stop within 120 seconds"
            ;;
        *) fail "run $run_id has unexpected state: $run_state" ;;
    esac
}

publish_release_set() {
    verify_release_set
    cancel_active_run

    release_base_url=$(gh variable get FMX_RELEASE_BASE_URL --repo "$repo")
    release_store=$(gh variable get FMX_RELEASE_STORE --repo "$repo")
    release_project=$(gh variable get FMX_RELEASE_PROJECT --repo "$repo" 2>/dev/null || true)
    [[ "$release_base_url" =~ ^https://[A-Za-z0-9][A-Za-z0-9.-]*\.public\.blob\.vercel-storage\.com(/[A-Za-z0-9._/-]+)?$ ]] \
        || fail 'FMX_RELEASE_BASE_URL is not a public Vercel Blob URL'
    [ -n "$release_store" ] || fail 'FMX_RELEASE_STORE is empty'

    credentials="$work_dir/vercel"
    mkdir -p "$credentials"
    scopes_json="$credentials/scopes.json"
    stores_json="$credentials/stores.json"
    (
        cd "$credentials"
        npx --yes "vercel@$vercel_version" teams list --json --limit 100 > "$scopes_json"
    )
    [ -z "$(jq -r '.pagination.next // empty' "$scopes_json")" ] \
        || fail 'Vercel account has more than 100 scopes; narrow discovery'
    jq -n '{stores: []}' > "$stores_json"
    while IFS= read -r scope; do
        [ -n "$scope" ] || continue
        scope_json="$credentials/stores-$scope.json"
        (
            cd "$credentials"
            npx --yes "vercel@$vercel_version" blob list-stores --all --json \
                --scope "$scope" > "$scope_json"
        )
        jq --arg scope "$scope" '{stores: [.stores[] | . + {release_scope: $scope}]}' \
            "$scope_json" > "$credentials/scoped.json"
        jq -s '{stores: (.[0].stores + .[1].stores)}' \
            "$stores_json" "$credentials/scoped.json" > "$credentials/combined.json"
        mv "$credentials/combined.json" "$stores_json"
    done < <(jq -r '.teams[].slug' "$scopes_json")

    store_count=$(jq --arg store "$release_store" \
        '[.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store)] | length' \
        "$stores_json")
    [ "$store_count" = 1 ] \
        || fail 'FMX_RELEASE_STORE does not identify exactly one visible store'
    store_id=$(jq -r --arg store "$release_store" \
        '.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .id' \
        "$stores_json")
    release_scope=$(jq -r --arg store "$release_store" \
        '.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .release_scope' \
        "$stores_json")
    if [ -n "$release_project" ]; then
        project_count=$(jq --arg store "$release_store" --arg project "$release_project" \
            '[.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .projects[] | select(.id == $project or .name == $project)] | length' \
            "$stores_json")
        project_id=$(jq -r --arg store "$release_store" --arg project "$release_project" \
            '.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .projects[] | select(.id == $project or .name == $project) | .id' \
            "$stores_json")
    else
        project_count=$(jq --arg store "$release_store" \
            '[.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .projects[]] | length' \
            "$stores_json")
        project_id=$(jq -r --arg store "$release_store" \
            '.stores[] | select(.id == $store or (.id | sub("^store_"; "")) == $store or .name == $store) | .projects[].id' \
            "$stores_json")
    fi
    [ "$project_count" = 1 ] && [[ "$project_id" =~ ^prj_[A-Za-z0-9]+$ ]] \
        || fail 'release store does not identify exactly one connected project'

    (
        cd "$credentials"
        npx --yes "vercel@$vercel_version" env pull .env.local --yes \
            --environment=development --project "$project_id" --scope "$release_scope"
    )
    pulled_store=$(sed -n 's/^BLOB_STORE_ID=//p' "$credentials/.env.local" | tail -n 1)
    pulled_store=${pulled_store#\"}
    pulled_store=${pulled_store%\"}
    [ "${pulled_store#store_}" = "${store_id#store_}" ] \
        || fail 'short-lived credentials identify another Blob store'
    oidc_token=$(sed -n 's/^VERCEL_OIDC_TOKEN=//p' "$credentials/.env.local" | tail -n 1)
    oidc_token=${oidc_token#\"}
    oidc_token=${oidc_token%\"}
    [[ "$oidc_token" =~ ^[A-Za-z0-9_.-]+$ ]] \
        || fail 'Vercel did not issue a short-lived OIDC token'
    export VERCEL_OIDC_TOKEN="$oidc_token"
    export BLOB_STORE_ID="$pulled_store"
    export VERCEL_PROJECT_ID="$project_id"
    export VERCEL_ENV=development

    base_without_scheme=${release_base_url#https://}
    case "$base_without_scheme" in
        */*) blob_prefix=${base_without_scheme#*/} ;;
        *) blob_prefix="" ;;
    esac
    blob_path() {
        if [ -n "$blob_prefix" ]; then printf '%s/%s' "$blob_prefix" "$1"
        else printf '%s' "$1"
        fi
    }
    blob_put() {
        local local_path="$1" relative_path="$2" content_type="$3"
        local overwrite="$4" max_age="$5"
        (
            cd "$credentials"
            if [ "$overwrite" = true ]; then
                npx --yes "vercel@$vercel_version" blob put "$local_path" \
                    --access public --pathname "$(blob_path "$relative_path")" \
                    --content-type "$content_type" --allow-overwrite=true \
                    --cache-control-max-age="$max_age"
            else
                npx --yes "vercel@$vercel_version" blob put "$local_path" \
                    --access public --pathname "$(blob_path "$relative_path")" \
                    --content-type "$content_type" \
                    --cache-control-max-age="$max_age"
            fi
        )
    }
    upload_immutable() {
        local local_path="$1" relative_path="$2" content_type="$3"
        local existing="$work_dir/existing"
        if curl_get "$release_base_url/$relative_path" -o "$existing" 2>/dev/null; then
            cmp -s "$local_path" "$existing" \
                || fail "immutable Blob path has different content: $relative_path"
            printf 'Already published: %s\n' "$relative_path"
            return 0
        fi
        blob_put "$local_path" "$relative_path" "$content_type" false 31536000
        printf 'Published: %s\n' "$relative_path"
    }

    for platform in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64; do
        for extension in tar.xz tar.gz; do
            archive="fmx-fx-$platform.$extension"
            content_type=application/gzip
            [ "$extension" = tar.xz ] && content_type=application/x-xz
            upload_immutable "$output/$archive" "fx/releases/$sha/$archive" "$content_type"
            upload_immutable "$output/$archive.sha256" "fx/releases/$sha/$archive.sha256" text/plain
        done
    done
    setup="$work_dir/fmx-setup.sh"
    sed "s|__FMX_FX_RELEASE_BASE_URL__|$release_base_url/fx|g" \
        "$worktree/fmx-setup.sh" > "$setup"
    bash -n "$setup"
    blob_put "$setup" fx/setup.sh text/x-shellscript true 300
    printf '%s' "$sha" > "$work_dir/latest.txt"
    blob_put "$work_dir/latest.txt" fx/latest.txt text/plain true 60

    public_get() {
        local url="$1" destination="$2"
        for _ in $(seq 1 30); do
            if curl_get "$url" -o "$destination" 2>/dev/null; then
                return 0
            fi
            sleep 2
        done
        curl_get "$url" -o "$destination"
    }
    for path in setup.sh latest.txt; do
        public_get "$release_base_url/fx/$path?verify=$sha" \
            "$work_dir/public-$path"
    done
    cmp -s "$setup" "$work_dir/public-setup.sh" \
        || fail 'public Fx setup.sh differs after publication'
    cmp -s "$work_dir/latest.txt" "$work_dir/public-latest.txt" \
        || fail 'public Fx latest.txt differs after publication'
    for local_path in "$output"/*; do
        name=$(basename "$local_path")
        public_get "$release_base_url/fx/releases/$sha/$name" \
            "$work_dir/public-$name"
        cmp -s "$local_path" "$work_dir/public-$name" \
            || fail "public artifact differs after publication: $name"
    done

    prune_historical_fx_releases() {
        local release_prefix keep_prefix listing pathname all_count
        local -a historical_paths=()
        release_prefix=$(blob_path fx/releases/)
        keep_prefix=$(blob_path "fx/releases/$sha/")
        (
            cd "$credentials"
            npx --yes "vercel@$vercel_version" blob list --limit 1000 \
                --mode expanded
        ) >"$work_dir/blob-list.txt" 2>&1
        listing=$(<"$work_dir/blob-list.txt")
        all_count=0
        while IFS= read -r pathname; do
            [ -n "$pathname" ] || continue
            all_count=$((all_count + 1))
            case "$pathname" in
                "$release_prefix"*)
                    case "$pathname" in
                        "$keep_prefix"*) ;;
                        *) historical_paths+=("$pathname") ;;
                    esac
                    ;;
            esac
        done < <(printf '%s\n' "$listing" \
            | awk 'NF >= 4 && $3 ~ /\// && $4 ~ /^https:\/\// { print $3 }')
        [ "$all_count" -lt 1000 ] \
            || fail 'Blob retention discovery reached its 1000-object bound'
        if [ "${#historical_paths[@]}" -eq 0 ]; then
            printf 'No historical fmx Fx releases to prune.\n'
            return 0
        fi
        for pathname in "${historical_paths[@]}"; do
            case "$pathname" in
                "$release_prefix"*) ;;
                *) fail "Blob retention selected an unrelated path: $pathname" ;;
            esac
            case "$pathname" in
                "$keep_prefix"*) fail "Blob retention selected the current release: $pathname" ;;
            esac
        done
        (
            cd "$credentials"
            npx --yes "vercel@$vercel_version" blob del "${historical_paths[@]}"
        )
        (
            cd "$credentials"
            npx --yes "vercel@$vercel_version" blob list --limit 1000 \
                --mode expanded
        ) >"$work_dir/blob-list-after-prune.txt" 2>&1
        while IFS= read -r pathname; do
            case "$pathname" in
                "$release_prefix"*)
                    case "$pathname" in
                        "$keep_prefix"*) ;;
                        *) fail "historical Blob path remains after pruning: $pathname" ;;
                    esac
                    ;;
            esac
        done < <(awk 'NF >= 4 && $3 ~ /\// && $4 ~ /^https:\/\// { print $3 }' \
            "$work_dir/blob-list-after-prune.txt")
        printf 'Pruned %s historical fmx Fx release objects.\n' \
            "${#historical_paths[@]}"
    }
    prune_historical_fx_releases

    receipt_dir="$state_root/fmx-releases"
    mkdir -p "$receipt_dir"
    artifact_json=$(for local_path in "$output"/*; do
        printf '%s  %s\n' "$(sha256_file "$local_path")" "$(basename "$local_path")"
    done | jq -Rn '[inputs | capture("^(?<sha256>[0-9a-f]{64})  (?<name>.+)$")]')
    receipt_temp=$(mktemp "$receipt_dir/.receipt.XXXXXX")
    jq -n --arg sha "$sha" --arg repo "$repo" --arg run_id "$run_id" \
        --arg release_base_url "$release_base_url" --arg published_at "$(date -u +%FT%TZ)" \
        --argjson artifacts "$artifact_json" \
        '{schema: 1, sha: $sha, repo: $repo, source_run_id: (if ($run_id | length) > 0 then $run_id else null end), release_base_url: $release_base_url, published_at: $published_at, artifacts: $artifacts}' \
        > "$receipt_temp"
    chmod 0600 "$receipt_temp"
    mv "$receipt_temp" "$receipt_dir/$sha.json"
    printf 'Published and verified fmx Fx %s (%s/fx/setup.sh)\n' "$sha" "$release_base_url"
}

case "$command_name" in
    build) build_release_set ;;
    verify) verify_release_set; printf 'Verified fmx Fx %s in %s\n' "$sha" "$output" ;;
    publish) publish_release_set ;;
esac
