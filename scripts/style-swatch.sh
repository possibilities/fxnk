#!/bin/bash
# Render style/tokens.json as a styled sample sheet on the current terminal.
#
# Every row paints its sample with the exact SGR sequence fx uses, then
# annotates it with the role name, the sequence, and the derived hex — so a
# developer or designer can eyeball the ramp and read the values in one place.
#
# Usage: style-swatch.sh [--theme dark|light|both]
#   dark rows read correctly on a dark terminal, light rows on a light one;
#   "both" (the default) prints the two sections regardless.

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tokens="$root/style/tokens.json"
theme=both

while [ $# -gt 0 ]; do
    case "$1" in
        --theme) theme="$2"; shift ;;
        *) printf 'style-swatch: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

[ -f "$tokens" ] || { printf 'style-swatch: %s missing; run scripts/style-extract.sh first\n' "$tokens" >&2; exit 1; }
command -v jq > /dev/null || { printf 'style-swatch: jq is required\n' >&2; exit 1; }

esc=$'\x1b'
reset="${esc}[0m"

# Convert the textual "\x1b[...m" form stored in tokens.json to live escapes.
live() { printf '%s' "${1//\\x1b/$esc}"; }

annotate() { # annotate <json-style-object> -> "seq  hex[/bg-hex]"
    jq -r '
        def hexes: [(.fg.hex // empty), (.bg.hex // empty)] | join(" on ");
        "\(.seq)  \(if (hexes | length) > 0 then hexes else "no color" end)\(if .bold then "  bold" else "" end)"'
} 

row() { # row <label> <sample> <style-json>
    local label=$1 sample=$2 style=$3 seq note
    seq=$(live "$(jq -r '.seq' <<< "$style")")
    note=$(annotate <<< "$style")
    printf '  %-22s %s%s%s  %s\n' "$label" "$seq" "$sample" "$reset" "$note"
}

section() { # section dark|light
    local t=$1 fx_commit
    fx_commit=$(jq -r '.generated.fx_commit[:7]' "$tokens")
    printf '\n%s━━ fx style swatch · %s theme · fx %s ━━%s\n\n' "${esc}[1m" "$t" "$fx_commit" "$reset"

    printf '  %sroles%s\n' "${esc}[1m" "$reset"
    local role
    for role in $(jq -r '.roles | keys_unsorted[]' "$tokens"); do
        row "$role" "the quick brown fox" "$(jq -c ".roles[\"$role\"].$t" "$tokens")"
    done

    printf '\n  %sdiff markers%s (theme-invariant; the one chromatic accent)\n' "${esc}[1m" "$reset"
    local ctx add rem addm remm
    ctx=$(live "$(jq -r ".roles.dim.$t.seq" "$tokens")")
    add=$(live "$(jq -r ".roles.diff_added.$t.seq" "$tokens")")
    rem=$(live "$(jq -r ".roles.diff_removed.$t.seq" "$tokens")")
    addm=$(live "$(jq -r '.diff_markers.added.truecolor.seq' "$tokens")")
    remm=$(live "$(jq -r '.diff_markers.removed.truecolor.seq' "$tokens")")
    printf '    %s  │ 41   fn hello() void {%s\n' "$ctx" "$reset"
    printf '    %s  │ %s42 -%s%s     return old_name();%s   %s\n' "$rem" "$remm" "$reset" "$rem" "$reset" "$(jq -c '.diff_markers.removed.truecolor' "$tokens" | annotate)"
    printf '    %s  │ %s42 +%s%s     return new_name();%s   %s\n' "$add" "$addm" "$reset" "$add" "$reset" "$(jq -c '.diff_markers.added.truecolor' "$tokens" | annotate)"

    printf '\n  %scode highlight%s\n' "${esc}[1m" "$reset"
    local kw str num cmt
    kw=$(live "$(jq -r ".code_highlight.$t.keyword.seq" "$tokens")")
    str=$(live "$(jq -r ".code_highlight.$t.string.seq" "$tokens")")
    num=$(live "$(jq -r ".code_highlight.$t.number.seq" "$tokens")")
    cmt=$(live "$(jq -r ".code_highlight.$t.comment.seq" "$tokens")")
    printf '    %sconst%s x = %s"ready"%s; %s// retries %s3%s times%s\n' "$kw" "$reset" "$str" "$reset" "$cmt" "$num" "$cmt" "$reset"
    printf '    keyword %s · string %s · number %s · comment %s\n' \
        "$(jq -r ".code_highlight.$t.keyword.fg.hex" "$tokens")" \
        "$(jq -r ".code_highlight.$t.string.fg.hex" "$tokens")" \
        "$(jq -r ".code_highlight.$t.number.fg.hex" "$tokens")" \
        "$(jq -r ".code_highlight.$t.comment.fg.hex" "$tokens")"

    printf '\n  %sassistant text%s\n' "${esc}[1m" "$reset"
    local inl task
    inl=$(live "$(jq -r ".assistant.inline_code.$t.seq" "$tokens")")
    task=$(live "$(jq -r ".assistant.task_completed.$t.seq" "$tokens")")
    printf '    run %szig build%s now · %s✓%s task done\n' "$inl" "${esc}[39m" "$task" "${esc}[39m"

    printf '\n  %suser prompt card%s\n' "${esc}[1m" "$reset"
    local rail acc bold_on
    rail=$(live "$(jq -r ".user_card.rail_marker.$t.seq" "$tokens")")
    acc=$(live "$(jq -r ".user_card.accent.$t.seq" "$tokens")")
    bold_on=$(live "$(jq -r '.user_card.prompt_text.seq' "$tokens")")
    printf '    %s%s%s %sfix the flaky test in %s/review%s%s please%s\n' \
        "$rail" "$(jq -r '.glyphs.user_turn_rail' "$tokens")" "$reset" "$bold_on" "$reset$acc" "$reset" "$bold_on" "$reset"

    printf '\n  %sglyphs%s\n' "${esc}[1m" "$reset"
    printf '    input prefix %s· user rail %s · tool ● / cancelled ■ · tree ├ └ · separator ·\n' \
        "$(jq -r '.glyphs.input_prefix' "$tokens")" "$(jq -r '.glyphs.user_turn_rail' "$tokens")"
    printf '\n'
}

case "$theme" in
    dark) section dark ;;
    light) section light ;;
    both) section dark; section light ;;
    *) printf 'style-swatch: --theme must be dark, light, or both\n' >&2; exit 2 ;;
esac
