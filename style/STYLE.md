# The fx style guide, for fmx

fx is the living style guide for fmx: whenever fmx draws its own chrome —
modals, toasts, panels, status rows — it should look like it belongs in the
same instrument as the fx it embeds. This document extracts fx's visual
language into rules and values fmx developers can borrow directly.

Ground truth is `style/tokens.json`, extracted from the fx source by
`scripts/style-extract.sh`; the tables here mirror it, and on any conflict
tokens.json wins. `style/captures/` holds rendered references: swatch sheets
(`cat style/captures/swatch-dark.ansi` in a dark terminal) and PNG screens of
the real binary. `MAINTAIN.md` § "Style guide" is the methodology for keeping
all of it current.

## The design language

fx is monochrome. Every semantic role — success, error, warning, accent —
collapses onto one grayscale ramp; the names stay semantic (`green_style`,
`red_style`) but the values are gray, so state is carried by glyph shape and
text, never by hue. Exactly one thing in the product is chromatic: the diff
marker (the `+`/`-` sign and line number), green `#30a46c` and red `#e5484d`.
That restraint is the look. Principles:

- **One ramp, few steps.** Dark theme uses five grays: primary `255`,
  accent `252`, secondary `250`, dim `245`, divider `240` (xterm-256
  indices). Light theme mirrors them: `235`, `238`, `241`, `247`, `250`.
- **Hierarchy by brightness and weight, not color.** Bold marks labels and
  titles; dimness marks chrome; the brightest gray marks what matters now.
- **One chromatic accent, spent on diffs.** Nothing else gets a hue. If
  everything is quiet, the one colored thing reads loudly.
- **Never paint a theme the terminal did not choose.** fx inherits light or
  dark from the terminal and restyles live when it changes. fmx already
  holds the same principle (its surfaces derive from the host palette);
  keep holding it.

## How fx themes itself

Two palettes — dark and light — and three ways to pick one:

1. **Explicit:** `FX_THEME=light|dark` (env var; the only explicit knob fx
   has — there is no config key, no custom colors).
2. **Implicit at startup:** OSC 11 query (`ESC ] 11 ; ? ST`) of the
   terminal's background; light when relative luminance > 50%. Fallback:
   `COLORFGBG`. Default: dark.
3. **Implicit live:** fx enables mode 2031 (`CSI ? 2031 h`) and listens for
   color-scheme notifications (`CSI ? 997 ; 1 n` dark, `CSI ? 997 ; 2 n`
   light), then re-queries OSC 11 (fenced by a DA1 `CSI c` round trip) and
   restyles the whole retained transcript in place.

Truecolor is assumed unless `TERM_PROGRAM=Apple_Terminal` without
`COLORTERM` (the one mainstream terminal that quantizes `38;2`); it is used
only for the diff markers, which fall back to indexed `71`/`167`.

### fmx is fx's terminal

fmx embeds fx in a PTY, so fmx is the "terminal" in everything above. The
edge obligations, all already implemented in `fmx/src/host-palette.ts` and
`fx-terminal.ts`, are:

- forward the host palette to the embedded terminal (OSC 4/10/11/…
  sequences from `buildHostPaletteSequence`) so fx's OSC 11 probe sees the
  real background;
- emit `themeModeReport` (the 997 notification) into fx when the host
  theme changes, since fx enabled mode 2031;
- let DA1 responses (`CSI ... c`) reach fx — it uses them as query fences;
- pass `FX_THEME` through untouched when the user sets it.

Change that file with this contract in mind; it is the live half of the
style edge this guide documents.

## Role tokens

fx's role palette lives in `src/ui/render.zig` (`initTheme`). Values below
are `xterm-256 index → hex`; hex is exact for these indices, so fmx can use
either form.

| role | dark | light | used for |
|---|---|---|---|
| hint | 255 `#eeeeee` | 235 `#262626` | primary text, keybinding hints |
| tag / subtitle | bold 255 | bold 235 | app tag, section titles |
| selected_completion | bold 255 | bold 235 | the selected menu row |
| system_notice_label | bold 252 `#d0d0d0` | bold 238 `#444444` | notice labels |
| warning / green / red / diff line text | 252 `#d0d0d0` | 238 `#444444` | semantic states, all deliberately the same gray |
| permission_auto | 252 | 238 | "auto"/"YOLO" in the statusline, one step brighter than its row |
| system_notice_text | 250 `#bcbcbc` | 241 `#626262` | notice body text |
| statusline | 245 `#8a8a8a` | 241 `#626262` | the status row |
| dim | 245 `#8a8a8a` | 247 `#9e9e9e` | secondary chrome, tool detail text |
| divider | 240 `#585858` | 250 `#bcbcbc` | horizontal rules |
| approval_button_active | bold 235 on 255 | bold 255 on 236 `#303030` | the focused button (inverse video) |
| approval_button_inactive | 255 on 239 `#4e4e4e` | 237 `#3a3a3a` on 251 `#c6c6c6` | unfocused buttons |

Note the compressions: `dim` and `statusline` share a value in dark but not
light; `warning`/`green`/`red` are one value everywhere. Borrow the *role*,
not the coincidence — tokens.json keys by role so the distinction survives.

## Satellite palettes

**Diff markers** — the only hue in the product. Line text stays neutral
(`252`/`238`); only the line number and sign are colored:
added `#30a46c` (fallback `38;5;71`), removed `#e5484d` (fallback
`38;5;167`), identical in both themes.

**Code highlight** (`code_highlight.zig`) — four slots, still grayscale:

| slot | dark | light |
|---|---|---|
| keyword | 252 `#d0d0d0` | 238 `#444444` |
| string / number | 250 `#bcbcbc` | 241 `#626262` |
| comment | 245 `#8a8a8a` | 243 `#767676` |

**Assistant text** (`presentation/ansi.zig`) — inline code dims to 245
(dark) / 247 (light); completed-task checkmarks use accent 252 / 238.

**User prompt card** (`user_message_card.zig`) — a `┃` rail in primary
(255 / 235), prompt text bold in the terminal's default foreground, skill
tokens in accent (252 / 238).

## The retint constraint

fx restyles its retained transcript on live theme change by literal byte
substitution over exactly six token pairs (`store.zig`,
`dark_to_light_theme_tokens`): `255↔235`, `252↔238`, `250↔241`, `245↔247`,
plus the bold variants of the first two. This is why fx has exactly two
palettes and why every fx surface writes only ramp values: any color outside
the map silently stays dark-tuned after a live switch. Two consequences for
fmx:

- fx cannot grow a third theme cheaply; do not design fmx features that
  assume it might.
- if fmx ever rewrites or synthesizes fx-styled bytes, use only ramp values
  from tokens.json, or live switching will strand them.

## Glyphs and typography

The glyph vocabulary carries the state that color does not:

| glyph | meaning |
|---|---|
| `❯ ` | input prompt prefix |
| `┃` | user prompt rail (left edge of submitted turns) |
| `●` | tool call marker — dim while running, accent gray when done |
| `■` | cancelled tool call |
| `├` `└` | tool-group tree connectors |
| `│` | diff / code block gutter |
| `·` | statusline field separator |
| `⏺` | "Asking" activity label |
| `✓` | completed task line |

Typography: **bold** for labels, titles, user prompt text, and the selected
row; *bold italic* for tool-group summaries; no underline except OSC 8
hyperlinks; no emoji anywhere in product output (fx house rule — Unicode
symbols like `✓` and `→` are fine).

## Borrowing into fmx

fmx's own surfaces (`host-palette.ts` `modalColors`) derive from the host
terminal's palette, which is *more* faithful to the shared principle than
fx's fixed grays. So the rule is not "copy the hex":

1. **Prefer host-derived colors** where fmx already derives them
   (foreground, background, dim-by-blending). fx's ramp tells you the
   *relationships* to reproduce: how far dim sits from primary, that
   dividers sit nearest the background, that selection is inversion.
2. **Use tokens.json hex as the fallback tier** — the values for a host
   that answers no color query — the role `MODAL_FALLBACK_COLORS` plays
   today. Aligning those fallbacks with the fx dark column keeps a
   no-answer host looking like one instrument.
3. **Spend chroma as rarely as fx does.** fmx's modal accent (host blue)
   and error (host red) are already more chromatic than fx; keep them for
   focus and failure, and resist adding more hues.
4. **Match the glyph vocabulary** where fmx shows the same concepts:
   agent/tool state dots, tree connectors, `·` separators, prompt rails.
5. **State by shape and weight first**, color second — a colorblind-safe
   habit fx enforces by having almost no color at all.

## Artifacts and regeneration

| artifact | what | regenerate with |
|---|---|---|
| `style/tokens.json` | machine-readable tokens, keyed by role, with SGR + hex per theme | `scripts/style-extract.sh` |
| `style/captures/swatch-*.{ansi,txt}` | styled sample sheet of every token | `scripts/style-capture.sh --swatch-only` |
| `style/captures/fx-welcome-*.{png,txt}` | the real binary's welcome screen, both themes | `scripts/style-capture.sh` |

`scripts/style-extract.sh --check` diffs a fresh extraction against the
committed tokens.json and fails on drift — run it whenever the fx checkout
moves. See `MAINTAIN.md` § "Style guide".
