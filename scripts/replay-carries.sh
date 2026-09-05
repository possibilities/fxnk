#!/bin/bash
# Replay every declared carry onto the cycle's captured upstream target in
# dependency order, then compose the graph's sinks into a candidate branch.
#
#   replay-carries.sh plan [--graph FILE]
#   replay-carries.sh replay   --checkout FX --root DIR --upstream SHA [--graph FILE] [--trailer TEXT]
#   replay-carries.sh continue --checkout FX --root DIR --upstream SHA [--graph FILE] [--trailer TEXT]
#   replay-carries.sh compose  --checkout FX --root DIR --branch NAME [--graph FILE] [--trailer TEXT]
#
# Each carry gets the worktree DIR/<carry> on branch carry/<carry>. A merge is
# skipped when its source is already contained, so a rerun is idempotent. A
# textual conflict stops with exit 2 and names the files. A merge that git
# completed only through recorded rerere resolutions is left staged and
# uncommitted with exit 3, after printing, per resolved file, the lines that
# exist on exactly one side of the merge and not in the result: a recorded
# resolution is evidence, not proof, and this is what a reviewer must read
# before `continue` commits it and carries on. Nothing here fetches, pushes,
# or moves a ref other than the carry heads it merges into.
set -euo pipefail

die() {
    printf 'replay-carries: %s\n' "$*" >&2
    exit 1
}

root_dir=$(cd "$(dirname "$0")/.." && pwd -P)
graph="$root_dir/scripts/carry-graph.tsv"
command=${1:-}
[ -n "$command" ] || die "usage: replay-carries.sh plan|replay|continue|compose|continue-compose ..."
shift
checkout='' worktree_root='' upstream='' branch='' trailer=''
while [ "$#" -gt 0 ]; do
    case "$1" in
        --graph) graph=$2; shift 2 ;;
        --checkout) checkout=$2; shift 2 ;;
        --root) worktree_root=$2; shift 2 ;;
        --upstream) upstream=$2; shift 2 ;;
        --branch) branch=$2; shift 2 ;;
        --trailer) trailer=$2; shift 2 ;;
        *) die "unknown argument: $1" ;;
    esac
done
[ -f "$graph" ] || die "graph not found: $graph"

# --- the graph ---------------------------------------------------------------

# The system bash is 3.2, so the graph is two parallel indexed arrays.
carries=()
carry_deps=()
while IFS=$'\t' read -r carry deps; do
    case "$carry" in ''|'#'*) continue ;; esac
    [[ "$carry" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid carry name in graph: $carry"
    [ -n "$deps" ] || die "graph row for $carry has no dependency column"
    for known in "${carries[@]+"${carries[@]}"}"; do
        [ "$known" != "$carry" ] || die "graph names $carry twice"
    done
    carries+=("$carry")
    carry_deps+=("$deps")
done <"$graph"
[ "${#carries[@]}" -gt 0 ] || die "graph declares no carry"

# deps_of CARRY prints the raw dependency column, or fails for an unknown carry.
deps_of() {
    local index
    for index in "${!carries[@]}"; do
        if [ "${carries[$index]}" = "$1" ]; then
            printf '%s\n' "${carry_deps[$index]}"
            return 0
        fi
    done
    return 1
}
[ "$(deps_of hosted-full-ci 2>/dev/null)" = upstream ] \
    || die "graph must declare hosted-full-ci, the common base, as depending on upstream"

# Dependencies of one carry as a list: the base first, then the declared
# dependencies in their listed order. Aliases and the base have none.
deps_list() {
    local carry=$1 deps dep
    deps=$(deps_of "$carry") || die "unknown carry: $carry"
    case "$deps" in
        upstream) return 0 ;;
        =*) printf '%s\n' "${deps#=}"; return 0 ;;
    esac
    printf '%s\n' hosted-full-ci
    [ "$deps" = - ] && return 0
    for dep in ${deps//,/ }; do
        deps_of "$dep" >/dev/null || die "$carry depends on undeclared carry: $dep"
        printf '%s\n' "$dep"
    done
}

is_placed() {
    case " $placed_names " in *" $1 "*) return 0 ;; esac
    return 1
}

# Topological order: repeatedly emit every carry whose dependencies are placed.
ordered=()
placed_names=
remaining=${#carries[@]}
while [ "$remaining" -gt 0 ]; do
    progressed=0
    for carry in "${carries[@]}"; do
        is_placed "$carry" && continue
        ready=1
        while IFS= read -r dep; do
            [ -n "$dep" ] || continue
            is_placed "$dep" || { ready=0; break; }
        done < <(deps_list "$carry")
        [ "$ready" -eq 1 ] || continue
        ordered+=("$carry")
        placed_names="$placed_names $carry"
        remaining=$((remaining - 1))
        progressed=1
    done
    [ "$progressed" -eq 1 ] || die "the carry graph has a cycle among:$(for c in "${carries[@]}"; do is_placed "$c" || printf ' %s' "$c"; done)"
done

# Sinks: carries no other carry depends on, excluding aliases and the base.
sinks=()
for carry in "${ordered[@]}"; do
    case "$(deps_of "$carry")" in upstream|=*) continue ;; esac
    used=0
    for other in "${carries[@]}"; do
        [ "$other" = "$carry" ] && continue
        while IFS= read -r dep; do
            [ "$dep" = "$carry" ] && { used=1; break; }
        done < <(deps_list "$other")
        [ "$used" -eq 1 ] && break
    done
    [ "$used" -eq 0 ] && sinks+=("$carry")
done

if [ "$command" = plan ]; then
    for carry in "${ordered[@]}"; do
        printf '%s\t%s\n' "$carry" "$(deps_list "$carry" | paste -sd, - )"
    done
    printf 'compose\t%s\n' "$(printf '%s\n' "${sinks[@]}" | paste -sd, -)"
    exit 0
fi

# --- worktrees and merges ----------------------------------------------------

[ -n "$checkout" ] || die "--checkout is required"
[ -n "$worktree_root" ] || die "--root is required"
[ "$(git -C "$checkout" rev-parse --is-inside-work-tree 2>/dev/null)" = true ] \
    || die "$checkout is not a git worktree"
mkdir -p "$worktree_root"
worktree_root=$(cd "$worktree_root" && pwd -P)

message_with_trailer() {
    if [ -n "$trailer" ]; then
        printf '%s\n\n%s\n' "$1" "$trailer"
    else
        printf '%s\n' "$1"
    fi
}

worktree_of() {
    local carry=$1 path="$worktree_root/$1"
    if [ ! -d "$path" ]; then
        git -C "$checkout" show-ref --verify --quiet "refs/heads/carry/$carry" \
            || die "carry/$carry is not a local branch of $checkout"
        git -C "$checkout" worktree add -q "$path" "carry/$carry" \
            || die "could not add a worktree for carry/$carry"
    fi
    [ "$(git -C "$path" rev-parse --abbrev-ref HEAD)" = "carry/$carry" ] \
        || die "$path is not on carry/$carry"
    printf '%s\n' "$path"
}

# recorded_files OUTPUT: the paths git filled from recorded rerere resolutions.
# With rerere.autoupdate git stages them ("Staged"); without it they sit
# resolved in the worktree but unmerged in the index ("Resolved"). Both are a
# reused resolution nobody has read yet.
recorded_files() {
    # BSD sed has no alternation in basic regular expressions.
    printf '%s\n' "$1" | sed -n -E "s/^(Staged|Resolved) '(.*)' using previous resolution.*$/\2/p"
}

# stage_recorded WORKTREE OUTPUT: bring "Resolved" paths into the index so the
# review below reads what continue would commit.
stage_recorded() {
    local worktree=$1 file
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        git -C "$worktree" add -- "$file"
    done < <(recorded_files "$2")
}

review_recorded() {
    # $1 worktree, $2 other side; stdin: the files git staged from a recorded
    # resolution. Print every line present on exactly one side but absent from
    # the staged result, which is what a reused resolution can silently drop.
    local worktree=$1 other=$2 file only_head only_other
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        only_head=$(comm -13 <(git -C "$worktree" show ":$file" | sort -u) \
            <(git -C "$worktree" show "HEAD:$file" | sort -u) | grep -v '^[[:space:]]*$' || true)
        only_other=$(comm -13 <(git -C "$worktree" show ":$file" | sort -u) \
            <(git -C "$worktree" show "$other:$file" | sort -u) | grep -v '^[[:space:]]*$' || true)
        printf 'REVIEW %s: %s line(s) only on HEAD, %s only on the merged side, absent from the result\n' \
            "$file" "$(printf '%s' "$only_head" | grep -c . || true)" "$(printf '%s' "$only_other" | grep -c . || true)"
        [ -z "$only_head" ] || printf '%s\n' "$only_head" | sed 's/^/  HEAD-only:   /'
        [ -z "$only_other" ] || printf '%s\n' "$only_other" | sed 's/^/  merged-only: /'
    done
}

# merge_into CARRY SOURCE SUBJECT: merge SOURCE into carry/CARRY's worktree.
merge_into() {
    local carry=$1 source=$2 subject=$3 worktree output status
    worktree=$(worktree_of "$carry")
    if [ -f "$(git -C "$worktree" rev-parse --git-path MERGE_HEAD)" ]; then
        die "carry/$carry has a merge in progress in $worktree; review it, then run continue or abort it"
    fi
    if git -C "$worktree" merge-base --is-ancestor "$source" HEAD; then
        printf 'skip   %-32s already contains %s\n' "$carry" "${source:0:12}"
        return 0
    fi
    set +e
    output=$(LC_ALL=C git -C "$worktree" merge --no-ff -m "$(message_with_trailer "$subject")" "$source" 2>&1)
    status=$?
    set -e
    if [ "$status" -eq 0 ]; then
        printf 'merged %-32s <- %s : %s\n' "$carry" "${source:0:12}" "$(git -C "$worktree" rev-parse --short HEAD)"
        return 0
    fi
    stage_recorded "$worktree" "$output"
    if [ -n "$(git -C "$worktree" diff --name-only --diff-filter=U)" ]; then
        printf 'CONFLICT %s <- %s: %s\n' "$carry" "${source:0:12}" \
            "$(git -C "$worktree" diff --name-only --diff-filter=U | paste -sd' ' -)"
        printf 'resolve it in %s, commit, then rerun\n' "$worktree"
        exit 2
    fi
    printf 'RECORDED %s <- %s: git completed the merge only through recorded resolutions\n' "$carry" "${source:0:12}"
    recorded_files "$output" | review_recorded "$worktree" "$source"
    printf 'review the lines above; `continue` commits the staged merge in %s and carries on\n' "$worktree"
    exit 3
}

continue_merges() {
    local carry worktree
    for carry in "${ordered[@]}"; do
        [ -d "$worktree_root/$carry" ] || continue
        worktree="$worktree_root/$carry"
        if [ -f "$(git -C "$worktree" rev-parse --git-path MERGE_HEAD)" ]; then
            [ -z "$(git -C "$worktree" diff --name-only --diff-filter=U)" ] \
                || die "carry/$carry still has unresolved paths"
            git -C "$worktree" commit -q --no-edit
            printf 'committed %-29s : %s\n' "$carry" "$(git -C "$worktree" rev-parse --short HEAD)"
        fi
    done
}

head_of() {
    git -C "$(worktree_of "$1")" rev-parse HEAD
}

# merge_into_candidate CARRY: compose one sink into the candidate worktree with
# the same conflict and recorded-resolution rules as a carry merge.
merge_into_candidate() {
    local carry=$1 source output status
    source=$(head_of "$carry")
    if [ -f "$(git -C "$candidate" rev-parse --git-path MERGE_HEAD)" ]; then
        die "the candidate has a merge in progress; review it, then run continue-compose or abort it"
    fi
    if git -C "$candidate" merge-base --is-ancestor "$source" HEAD; then
        printf 'skip   candidate already contains carry/%s\n' "$carry"
        return 0
    fi
    set +e
    output=$(LC_ALL=C git -C "$candidate" merge --no-ff \
        -m "$(message_with_trailer "Compose carry/$carry into Integration")" "$source" 2>&1)
    status=$?
    set -e
    if [ "$status" -eq 0 ]; then
        printf 'composed carry/%-26s : %s\n' "$carry" "$(git -C "$candidate" rev-parse --short HEAD)"
        return 0
    fi
    stage_recorded "$candidate" "$output"
    if [ -n "$(git -C "$candidate" diff --name-only --diff-filter=U)" ]; then
        printf 'CONFLICT candidate <- carry/%s: %s\n' "$carry" \
            "$(git -C "$candidate" diff --name-only --diff-filter=U | paste -sd' ' -)"
        exit 2
    fi
    printf 'RECORDED candidate <- carry/%s: git completed the merge only through recorded resolutions\n' "$carry"
    recorded_files "$output" | review_recorded "$candidate" "$source"
    printf 'review the lines above; `continue-compose` commits the staged merge and carries on\n'
    exit 3
}

case "$command" in
    replay|continue)
        [ -n "$upstream" ] || die "--upstream is required"
        [[ "$upstream" =~ ^[0-9a-f]{40}$ ]] || die "--upstream must be one exact commit SHA"
        git -C "$checkout" cat-file -e "$upstream^{commit}" 2>/dev/null \
            || die "$checkout does not contain the captured upstream $upstream"
        [ "$command" = continue ] && continue_merges
        for carry in "${ordered[@]}"; do
            case "$(deps_of "$carry")" in
                upstream)
                    merge_into "$carry" "$upstream" "Merge captured upstream ${upstream:0:12} into carry/$carry"
                    ;;
                =*)
                    alias_of=$(deps_of "$carry"); alias_of=${alias_of#=}
                    worktree=$(worktree_of "$carry")
                    target=$(head_of "$alias_of")
                    if [ "$(git -C "$worktree" rev-parse HEAD)" != "$target" ]; then
                        git -C "$worktree" merge -q --ff-only "$target" \
                            || die "carry/$carry cannot fast-forward to carry/$alias_of"
                        printf 'ff     %-32s -> %s\n' "$carry" "${target:0:12}"
                    else
                        printf 'skip   %-32s shares carry/%s\n' "$carry" "$alias_of"
                    fi
                    ;;
                *)
                    while IFS= read -r dep; do
                        [ -n "$dep" ] || continue
                        merge_into "$carry" "$(head_of "$dep")" "Merge carry/$dep into carry/$carry"
                    done < <(deps_list "$carry")
                    ;;
            esac
        done
        printf 'REPLAY COMPLETE\n'
        ;;
    continue-compose)
        candidate="$worktree_root/candidate"
        [ -d "$candidate" ] || die "no candidate worktree under $worktree_root"
        if [ -f "$(git -C "$candidate" rev-parse --git-path MERGE_HEAD)" ]; then
            [ -z "$(git -C "$candidate" diff --name-only --diff-filter=U)" ] \
                || die "the candidate still has unresolved paths"
            git -C "$candidate" commit -q --no-edit
            printf 'committed candidate : %s\n' "$(git -C "$candidate" rev-parse --short HEAD)"
        fi
        for carry in "${sinks[@]}"; do
            merge_into_candidate "$carry"
        done
        printf 'COMPOSED %s\n' "$(git -C "$candidate" rev-parse HEAD)"
        ;;
    compose)
        [ -n "$branch" ] || die "--branch is required"
        candidate="$worktree_root/candidate"
        base=$(head_of hosted-full-ci)
        if [ ! -d "$candidate" ]; then
            git -C "$checkout" worktree add -q -b "$branch" "$candidate" "$base" \
                || die "could not add the candidate worktree"
        else
            [ -z "$(git -C "$candidate" status --porcelain)" ] || die "candidate worktree is dirty"
            git -C "$candidate" checkout -q -B "$branch" "$base"
        fi
        for carry in "${sinks[@]}"; do
            merge_into_candidate "$carry"
        done
        printf 'COMPOSED %s\n' "$(git -C "$candidate" rev-parse HEAD)"
        ;;
    *)
        die "unknown command: $command"
        ;;
esac
