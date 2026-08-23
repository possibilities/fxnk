#!/bin/bash
# Extract fx's styling tokens from the bound checkout into style/tokens.json.
#
# Reads (never writes) the fx checkout. Parses the known styling sites:
#   src/ui/render.zig                      role palette (initTheme dark/light)
#   src/ui/render_engine/code_highlight.zig  syntax highlight palettes
#   src/core/agent/presentation/ansi.zig     inline code + task checkmark
#   src/ui/assistant/user_message_card.zig   prompt rail + skill-token accent
#   src/ui/transcript/store.zig              dark<->light retint map
#
# Exits nonzero when any site fails to parse, so an fx refactor is loud.
# See MAINTAIN.md "Style guide" for the discovery method behind these sites.
#
# Usage: style-extract.sh [--check] [--fx DIR]
#   --check   regenerate to a temp file and diff against the committed
#             style/tokens.json (ignoring the generated stamp); exit 1 on drift
#   --fx DIR  fx checkout to read (default: $FX_CHECKOUT or ~/src/fx)

set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
fx="${FX_CHECKOUT:-$HOME/src/fx}"
check=0

while [ $# -gt 0 ]; do
    case "$1" in
        --check) check=1 ;;
        --fx) fx="$2"; shift ;;
        *) printf 'style-extract: unknown argument %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done

fail() {
    printf 'style-extract: %s\n' "$*" >&2
    exit 1
}

render="$fx/src/ui/render.zig"
highlight="$fx/src/ui/render_engine/code_highlight.zig"
ansi="$fx/src/core/agent/presentation/ansi.zig"
card="$fx/src/ui/assistant/user_message_card.zig"
store="$fx/src/ui/transcript/store.zig"

for f in "$render" "$highlight" "$ansi" "$card" "$store"; do
    [ -f "$f" ] || fail "missing source file: $f (fx refactor? see MAINTAIN.md Style guide)"
done

commit=$(git -C "$fx" rev-parse HEAD)
ref=$(git -C "$fx" branch --show-current 2>/dev/null || true)
[ -n "$ref" ] || ref=detached

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v fx_commit="$commit" -v fx_ref="$ref" '
# ---- helpers ----------------------------------------------------------------

function cube_channel(x) { return x == 0 ? 0 : 55 + 40 * x }

function index_hex(n,    c, r, g, b, v) {
    if (n >= 232) { v = 8 + (n - 232) * 10; return sprintf("#%02x%02x%02x", v, v, v) }
    if (n >= 16) {
        c = n - 16
        r = int(c / 36); g = int((c % 36) / 6); b = c % 6
        return sprintf("#%02x%02x%02x", cube_channel(r), cube_channel(g), cube_channel(b))
    }
    return base16[n]
}

# Parse a Zig string literal content like "\x1b[1;38;5;255m\x1b[48;5;236m"
# (backslashes are literal characters here) into a JSON style object.
function style_json(content,    out, chunks, n, i, params, p, m, j, fg, bg, bold, seq) {
    fg = ""; bg = ""; bold = 0
    n = split(content, chunks, /\\x1b\[/)
    for (i = 2; i <= n; i++) {
        seq = chunks[i]
        if (seq !~ /m$/) { parse_errors = parse_errors "unterminated SGR in \"" content "\"; " ; continue }
        sub(/m$/, "", seq)
        m = split(seq, params, ";")
        for (j = 1; j <= m; j++) {
            p = params[j]
            if (p == "0") { continue }
            else if (p == "1") { bold = 1 }
            else if ((p == "38" || p == "48") && j + 1 <= m) {
                if (params[j+1] == "5" && j + 2 <= m) {
                    if (p == "38") fg = indexed_json(params[j+2] + 0)
                    else bg = indexed_json(params[j+2] + 0)
                    j += 2
                } else if (params[j+1] == "2" && j + 4 <= m) {
                    if (p == "38") fg = rgb_json(params[j+2]+0, params[j+3]+0, params[j+4]+0)
                    else bg = rgb_json(params[j+2]+0, params[j+3]+0, params[j+4]+0)
                    j += 4
                } else {
                    parse_errors = parse_errors "unrecognized color form in \"" content "\"; "
                }
            } else {
                parse_errors = parse_errors "unrecognized SGR param " p " in \"" content "\"; "
            }
        }
    }
    out = "{\"seq\":\"" json_escape(content) "\""
    out = out ",\"bold\":" (bold ? "true" : "false")
    out = out ",\"fg\":" (fg == "" ? "null" : fg)
    out = out ",\"bg\":" (bg == "" ? "null" : bg)
    return out "}"
}

function indexed_json(n) {
    return "{\"model\":\"indexed\",\"index\":" n ",\"hex\":\"" index_hex(n) "\"}"
}

function rgb_json(r, g, b) {
    return "{\"model\":\"rgb\",\"hex\":\"" sprintf("#%02x%02x%02x", r, g, b) "\"}"
}

function json_escape(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }

function quoted_content(line,    q1, rest, q2) {
    q1 = index(line, "\"")
    if (q1 == 0) return ""
    rest = substr(line, q1 + 1)
    q2 = index(rest, "\"")
    if (q2 == 0) return ""
    return substr(rest, 1, q2 - 1)
}

function basename(path,    parts, n) { n = split(path, parts, "/"); return parts[n] }

BEGIN {
    base16[0]="#000000"; base16[1]="#800000"; base16[2]="#008000"; base16[3]="#808000"
    base16[4]="#000080"; base16[5]="#800080"; base16[6]="#008080"; base16[7]="#c0c0c0"
    base16[8]="#808080"; base16[9]="#ff0000"; base16[10]="#00ff00"; base16[11]="#ffff00"
    base16[12]="#0000ff"; base16[13]="#ff00ff"; base16[14]="#00ffff"; base16[15]="#ffffff"
    parse_errors = ""
    role_count["dark"] = 0; role_count["light"] = 0
    retint_count = 0
}

FNR == 1 { file = basename(FILENAME); region = ""; in_init = 0; pal = ""; rt = 0 }

# ---- src/ui/render.zig ------------------------------------------------------

file == "render.zig" && /^pub fn initTheme/ { in_init = 1 }
file == "render.zig" && in_init && /^}$/ { in_init = 0; region = "" }
file == "render.zig" && in_init && /^    if \(light\) \{/ { region = "light"; next }
file == "render.zig" && in_init && /^    \} else \{/ { region = "dark"; next }
file == "render.zig" && in_init && region != "" && /^    \}$/ { region = ""; next }
file == "render.zig" && in_init && region != "" && /^        [a-z_]+ = "/ {
    name = $1
    content = quoted_content($0)
    if (content == "") { parse_errors = parse_errors "empty role value for " name "; " }
    if (!(name in role_seen)) { role_order[++role_n] = name; role_seen[name] = 1 }
    roles[region "\t" name] = content
    role_count[region]++
}
file == "render.zig" && /^const diff_(added|removed)_marker_(truecolor|fallback) = "/ {
    diff_markers[$2] = quoted_content($0)
    diff_marker_count++
}
file == "render.zig" && /^pub const input_prefix = "/ { glyphs["input_prefix"] = quoted_content($0) }
file == "render.zig" && /^pub const right_tag = "/ { glyphs["right_tag"] = quoted_content($0) }
file == "render.zig" && /^pub const ask_activity_label = "/ { glyphs["ask_activity_label"] = quoted_content($0) }

# ---- src/ui/render_engine/code_highlight.zig --------------------------------

file == "code_highlight.zig" && /^const dark_palette/ { pal = "dark"; next }
file == "code_highlight.zig" && /^const light_palette/ { pal = "light"; next }
file == "code_highlight.zig" && pal != "" && /^\};/ { pal = ""; next }
file == "code_highlight.zig" && pal != "" && /^    \.[a-z_]+_style = "/ {
    name = $1
    sub(/^\./, "", name)
    if (!(name in hl_seen)) { hl_order[++hl_n] = name; hl_seen[name] = 1 }
    hl[pal "\t" name] = quoted_content($0)
    hl_count[pal]++
}

# ---- src/core/agent/presentation/ansi.zig -----------------------------------

file == "ansi.zig" && /^const (task_completed|inline_code)_(dark|light)_open = "/ {
    ansi_tokens[$2] = quoted_content($0)
    ansi_count++
}

# ---- src/ui/assistant/user_message_card.zig ---------------------------------

file == "user_message_card.zig" && /^const (dark|light)_marker_style = "/ {
    card[$2] = quoted_content($0); card_count++
}
file == "user_message_card.zig" && /^const accent_(dark|light) = "/ {
    card[$2] = quoted_content($0); card_count++
}
file == "user_message_card.zig" && /^const prompt_text_style = / {
    card["prompt_text_style"] = quoted_content($0); card_count++
}
file == "user_message_card.zig" && /^const user_turn_rail = "/ {
    glyphs["user_turn_rail"] = quoted_content($0)
}

# ---- src/ui/transcript/store.zig --------------------------------------------

file == "store.zig" && /^const dark_to_light_theme_tokens/ { rt = 1; next }
file == "store.zig" && rt && /^\};/ { rt = 0; next }
file == "store.zig" && rt && /\.from = "/ {
    n = split($0, qq, "\"")
    if (n >= 5) {
        retint_from[++retint_count] = qq[2]
        retint_to[retint_count] = qq[4]
    } else {
        parse_errors = parse_errors "unparseable retint entry: " $0 "; "
    }
}

# ---- emit -------------------------------------------------------------------

END {
    # Validation: every site must have produced its expected shape.
    required_roles = "divider_style hint_style statusline_style tag_style subtitle_style system_notice_label_style system_notice_text_style dim_style warning_style green_style red_style diff_added_style diff_removed_style approval_button_active_style approval_button_inactive_style selected_completion_style permission_auto_style"
    split(required_roles, req, " ")
    for (i in req) {
        if (!(("dark" "\t" req[i]) in roles)) parse_errors = parse_errors "missing dark role " req[i] "; "
        if (!(("light" "\t" req[i]) in roles)) parse_errors = parse_errors "missing light role " req[i] "; "
    }
    if (role_count["dark"] != role_count["light"]) parse_errors = parse_errors "dark/light role counts differ (" role_count["dark"] " vs " role_count["light"] "); "
    if (diff_marker_count != 4) parse_errors = parse_errors "expected 4 diff marker consts, found " diff_marker_count "; "
    if (hl_count["dark"] < 4 || hl_count["light"] < 4) parse_errors = parse_errors "code highlight palettes incomplete; "
    if (ansi_count != 4) parse_errors = parse_errors "expected 4 ansi.zig consts, found " ansi_count "; "
    if (card_count < 5) parse_errors = parse_errors "user_message_card consts incomplete (" card_count "); "
    if (retint_count < 1) parse_errors = parse_errors "retint map empty; "
    if (!("input_prefix" in glyphs) || !("user_turn_rail" in glyphs)) parse_errors = parse_errors "glyph consts missing; "

    if (parse_errors != "") {
        printf "style-extract: parse failure: %s\n", parse_errors > "/dev/stderr"
        exit 1
    }

    printf "{\n"
    printf "  \"generated\": {\"script\": \"scripts/style-extract.sh\", \"fx_checkout\": \"~/src/fx\", \"fx_ref\": \"%s\", \"fx_commit\": \"%s\"},\n", fx_ref, fx_commit
    printf "  \"roles\": {\n"
    for (i = 1; i <= role_n; i++) {
        name = role_order[i]
        short = name
        sub(/_style$/, "", short)
        printf "    \"%s\": {\"dark\": %s, \"light\": %s}%s\n", short, \
            style_json(roles["dark" "\t" name]), style_json(roles["light" "\t" name]), \
            (i < role_n ? "," : "")
    }
    printf "  },\n"
    printf "  \"diff_markers\": {\n"
    printf "    \"added\": {\"truecolor\": %s, \"fallback\": %s},\n", style_json(diff_markers["diff_added_marker_truecolor"]), style_json(diff_markers["diff_added_marker_fallback"])
    printf "    \"removed\": {\"truecolor\": %s, \"fallback\": %s}\n", style_json(diff_markers["diff_removed_marker_truecolor"]), style_json(diff_markers["diff_removed_marker_fallback"])
    printf "  },\n"
    printf "  \"code_highlight\": {\n"
    printf "    \"dark\": {"
    for (i = 1; i <= hl_n; i++) {
        name = hl_order[i]; short = name; sub(/_style$/, "", short)
        printf "%s\"%s\": %s", (i > 1 ? ", " : ""), short, style_json(hl["dark" "\t" name])
    }
    printf "},\n    \"light\": {"
    for (i = 1; i <= hl_n; i++) {
        name = hl_order[i]; short = name; sub(/_style$/, "", short)
        printf "%s\"%s\": %s", (i > 1 ? ", " : ""), short, style_json(hl["light" "\t" name])
    }
    printf "}\n  },\n"
    printf "  \"assistant\": {\n"
    printf "    \"inline_code\": {\"dark\": %s, \"light\": %s},\n", style_json(ansi_tokens["inline_code_dark_open"]), style_json(ansi_tokens["inline_code_light_open"])
    printf "    \"task_completed\": {\"dark\": %s, \"light\": %s}\n", style_json(ansi_tokens["task_completed_dark_open"]), style_json(ansi_tokens["task_completed_light_open"])
    printf "  },\n"
    printf "  \"user_card\": {\n"
    printf "    \"rail_marker\": {\"dark\": %s, \"light\": %s},\n", style_json(card["dark_marker_style"]), style_json(card["light_marker_style"])
    printf "    \"accent\": {\"dark\": %s, \"light\": %s},\n", style_json(card["accent_dark"]), style_json(card["accent_light"])
    printf "    \"prompt_text\": %s\n", style_json(card["prompt_text_style"])
    printf "  },\n"
    printf "  \"retint_map\": [\n"
    for (i = 1; i <= retint_count; i++) {
        printf "    {\"dark\": %s, \"light\": %s}%s\n", style_json(retint_from[i]), style_json(retint_to[i]), (i < retint_count ? "," : "")
    }
    printf "  ],\n"
    printf "  \"glyphs\": {\n"
    printf "    \"input_prefix\": \"%s\",\n", json_escape(glyphs["input_prefix"])
    printf "    \"user_turn_rail\": \"%s\",\n", json_escape(glyphs["user_turn_rail"])
    printf "    \"right_tag\": \"%s\",\n", json_escape(glyphs["right_tag"])
    printf "    \"ask_activity_label\": \"%s\"\n", json_escape(glyphs["ask_activity_label"])
    printf "  }\n"
    printf "}\n"
}
' "$render" "$highlight" "$ansi" "$card" "$store" > "$tmp"

jq . "$tmp" > /dev/null || fail "generated tokens are not valid JSON (bug in extractor)"

out="$root/style/tokens.json"

if [ "$check" = 1 ]; then
    [ -f "$out" ] || fail "--check: no committed style/tokens.json to compare against"
    if diff <(jq -S 'del(.generated)' "$out") <(jq -S 'del(.generated)' "$tmp") > /dev/null; then
        printf 'style-extract: no drift (fx %s)\n' "${commit:0:7}"
        exit 0
    fi
    printf 'style-extract: DRIFT against fx %s — token differences:\n' "${commit:0:7}" >&2
    diff <(jq -S 'del(.generated)' "$out") <(jq -S 'del(.generated)' "$tmp") >&2 || true
    exit 1
fi

mv "$tmp" "$out"
trap - EXIT
printf 'style-extract: wrote style/tokens.json from fx %s (%s)\n' "${commit:0:7}" "$ref"
