# The fxnk style guide

fx is the living style guide for fxnk-based surfaces. Whenever fmx draws its
own chrome — or an OpenTUI host such as agentbrowse frames a native surface —
it should look like it belongs in the same instrument as fx. This document
extracts fx's visual language into rules and values those developers can
borrow directly.

Ground truth is `style/tokens.json`, extracted from the fx source by
`scripts/style-extract.sh`; the tables here mirror it, and on any conflict
tokens.json wins. `style/captures/` holds rendered references: swatch sheets
(`cat style/captures/swatch-dark.ansi` in a dark terminal) and PNG screens of
the real binary; `scripts/style-view.sh` opens the interactive viewer —
sections for roles, an assembled transcript, code, glyphs, and the
carve-outs, with a dark/light toggle. `MAINTAIN.md` § "Style guide" is the methodology for keeping
all of it current.

## The design language

fx is monochrome. Every semantic role — success, error, warning, accent —
collapses onto one grayscale ramp; the names stay semantic (`green_style`,
`red_style`) but the values are gray, so state is carried by glyph shape and
text, never by hue. Exactly one thing in the product is chromatic: the diff
marker (the `+`/`-` sign and line number), green `#30a46c` and red `#e5484d`.
That restraint is the look. Principles:

fxnk and Signal Room are complete, mutually exclusive design languages.
Never combine their tokens, components, borders, or layout vocabulary in one
application. An explicit user or project choice wins. Without one, infer from
the application's established repository precedent; if that evidence is not
reliable, ask the human before designing.

- **One ramp, few steps.** Dark theme uses five grays: primary `255`,
  accent `252`, secondary `250`, dim `245`, divider `240` (xterm-256
  indices). Light theme mirrors them: `235`, `238`, `241`, `247`, `250`.
- **Hierarchy by brightness and weight, not color.** Bold marks labels and
  titles; dimness marks chrome; the brightest gray marks what matters now.
- **One chromatic accent, spent on diffs.** Nothing else gets a hue. If
  everything is quiet, the one colored thing reads loudly.
- **The terminal chooses the set, not the colors in it.** fx inherits light or
  dark from the terminal and restyles live when it changes, but each set is
  the fixed indexed palette above. Never sample the host palette or derive a
  third grayscale ramp from its foreground and background.

## How fx themes itself

Two palettes — dark and light — and three ways to pick one:

1. **Explicit:** `FX_THEME=light|dark` (env var; the only explicit knob fx
   has — there is no config key, no custom colors).
2. **Implicit at startup:** one app-owned OSC 11 query (`ESC ] 11 ; ? ST`) of the
   terminal's background; light when relative luminance > 50%. The response
   deadline is 200 ms. Fallback: `COLORFGBG`. Default: dark. This is only a
   mode query: the fxnk theme layer does not query OSC 10, OSC 4, or the full
   host palette. A UI toolkit may own an independent capability handshake;
   its color results never select or alter fxnk tokens.
3. **Implicit live:** fx enables mode 2031 (`CSI ? 2031 h`) and listens for
   color-scheme notifications (`CSI ? 997 ; 1 n` dark, `CSI ? 997 ; 2 n`
   light), then re-queries OSC 11 (fenced by a DA1 `CSI c` round trip) and
   restyles the whole retained transcript in place.

Truecolor is assumed unless `TERM_PROGRAM=Apple_Terminal` without
`COLORTERM` (the one mainstream terminal that quantizes `38;2`); it is used
only for the diff markers, which fall back to indexed `71`/`167`.

### fmx is fx's terminal

fmx embeds fx in a PTY, so fmx is the "terminal" in everything above. The
edge obligations, implemented in `fmx/src/host-palette.ts` and
`fx-terminal.ts`, are:

- resolve the outer mode with the same precedence and the same single app-owned
  OSC 11 query before the first frame; a timed-out initial response is ignored
  and never applied late;
- set only the embedded terminal's OSC 11 default background, so fx's own
  probe selects the same mode; never mirror OSC 4, OSC 10, cursor, highlight,
  or other host-palette values;
- emit `themeModeReport` (the 997 notification) into fx after a genuine outer
  theme change, since fx enabled mode 2031;
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

## Carve-outs: what fx has no surface for

fx is a transcript with a prompt; it has no tray, overlaid stage surfaces, or
shared Client field. When fmx needs a surface fx never draws, the rule is to
build it from fx's principles — one ramp, weight and glyph for state, no hue,
no underline — and record it here as a carve-out. Nothing below is extracted from fx:
`tokens.json` does not carry it, `style-extract.sh --check` cannot see it,
and a maintenance cycle must not "correct" it back to fx.

### Unused space around a smaller sizing owner

fmx renders one shared Runtime at the dimensions of the Client that most
recently connected or interacted. When another Client's physical terminal is
larger than that sizing-owner frame, its extra cells on the right and bottom
are neither another pane nor a navigable viewport. They are one flat
**unused field** behind the shared frame at the top left.

| part | dark | light |
|---|---|---|
| shared frame | terminal default background | terminal default background |
| unused field | indexed 235 `#262626` | indexed 255 `#eeeeee` |

The color difference is the whole affordance. There is no boundary line or
outer border, and no glyph, hatch, grid, dither, noise, or other texture. On
each sizing handoff fmx paints the physical Client with the unused field,
then paints the owner-sized shared frame over its top-left corner. The field
should read as the same instrument falling quiet, not as a second surface.

A physically smaller observing Client simply crops the shared frame at the
right and bottom; there is no pan, scroll, or viewport behavior. Connecting,
focus gain, keyboard input, mouse motion or buttons, paste, and resize can
make that Client the sizing owner, at which point the Runtime organically
resizes and every Client repaints.

Why this shape: a border made the shared frame look nested, and any repeated
mark made unused space compete with the work. A fixed theme-step field is
visible without becoming content of its own.

### Agent rows in the tray

fx has no tray: its transcript is one agent. fmx's Session list
(`fmx/src/session-list.ts`) draws a project → branch → agent tree, and the
state of every agent in it — which fx would say in words — has to be read
off a glyph. The row is built from fx's principles: the brightest gray marks
what matters now, bold marks the path, and no state is a hue.

```
 fmx
   main
     × needs-permission
     ◐ implement-gallery      ← active: surface fill
     ✓ review-complete
     ○ available
   (untracked)
     · starting
```

| part | role | dark | light |
|---|---|---|---|
| project / branch label | `hint` (primary); bold on the path to the active agent | 255 | 235 |
| `(untracked)` virtual branch | `system_notice_text` (secondary), italic, never bold | 250 | 241 |
| agent / subagent name | `dim` | 245 | 247 |
| blocked glyph `×` `?` `↻` | **bold `hint`** — the one bright thing, what needs the human | bold 255 | bold 235 |
| done glyph `✓` | `permission_auto` (accent) — one step brighter than its row, fx's finished-tool idiom | 252 | 238 |
| working `◐`, idle `○`, unknown `·` glyphs | `dim` | 245 | 247 |
| active row | surface fill, indexed 236 `#303030` | indexed 254 `#e4e4e4` |

Why this shape: fx marks a running tool call dim and a finished one accent,
which is exactly the working/done pair; blocked takes the brightest gray and
bold because in fx's language "what matters now" is the only thing allowed
to be loud. The fill rather than inversion or bold for the active row: bold
is already the path, and fx's inverse-video button is far too loud for a
row that is on screen all day. The mode is resolved before the first frame,
so names use the selected set's `dim` token immediately. Not taken: the five ANSI status
hues fmx used before this guide (red/yellow/cyan/green/gray — state by hue,
which fx forbids), and a red "attention" exception for blocked (one
more hue than fx spends, and the bold glyph already reads first).

### Surfaces over the stage

fx has no modal, dialog, or picker; its prompts are inline. fmx's help modal
and spawn error (`fmx/src/multiplexer.ts`), launch dialog, and project/model
pickers (`fmx/src/launch-dialog.ts`) are one family: a bordered body over a
dimmed stage.

```
┌─ launch ─────────────────────────────┐
│ ▎ prompt    what should the agent do?│      focus border: this takes keys
│   project   ~/code/fmx               │
│   worktree  no                       │
└──────────────────────────────────────┘
```

| part | role | dark | light |
|---|---|---|---|
| scrim behind a modal or dialog | `#00000033` — a 20% black darkening, fmx's one opacity; not a hue, and reads as a dimmed stage on either theme | — | — |
| body | terminal default background | — | — |
| border, surface that takes keys | **focus** — direct ANSI index 4; terminal-defined blue | 4 | 4 |
| border, surface reporting a failure | **error** — direct ANSI index 1; terminal-defined red | 1 | 1 |
| title in the border | `hint` (primary) | 255 | 235 |
| label — a dialog row's name, a help key (bold) | `system_notice_text` (secondary) | 250 | 241 |
| value, body text | `hint` (primary) | 255 | 235 |
| standing hint, placeholder, an unavailable row's reason | `dim` | 245 | 247 |
| error heading | bold `red` — which in fx is the accent gray | bold 252 | bold 238 |
| row caret `▎`, picker `> `, prompt cursor | **focus** | — | — |
| selected picker row | `selected_completion` (bold primary) | bold 255 | bold 235 |
| other picker rows | `system_notice_text` (secondary) | 250 | 241 |

Why this shape: focus is the one hue fx's guide lets fmx keep, and "this
surface has your keys" is what focus means, so every surface that takes
keys wears it on its border and nowhere else takes it. The picker is fx's
completion menu (selected row bold primary). The help modal's key/description
pairs and the dialog's label/value pairs are fx's notice-label/notice-text
pairing. Not taken: red text inside the error modal (the border already says
failure; one red per surface), bold titles (OpenTUI box titles take a color
only).

## Borrowing into fmx

fmx and every fxnk-based OpenTUI app use the same fixed indexed sets as fx.
The terminal supplies only the default background and the dark/light choice:

| ramp step | dark | light |
|---|---|---|
| foreground / primary | 255 `#eeeeee` | 235 `#262626` |
| accent | 252 `#d0d0d0` | 238 `#444444` |
| secondary | 250 `#bcbcbc` | 241 `#626262` |
| dim | 245 `#8a8a8a` | 247 `#9e9e9e` |
| divider | 240 `#585858` | 250 `#bcbcbc` |
| surface (carve-out) | 236 `#303030` | 254 `#e4e4e4` |
| unused field (carve-out) | 235 `#262626` | 255 `#eeeeee` |
| background | terminal default (`SGR 49`) | terminal default (`SGR 49`) |

1. **Resolve before first paint.** Use the fx precedence exactly:
   case-insensitive `FX_THEME=light|dark`, one OSC 11 background query,
   `COLORFGBG`, then dark. A late initial OSC 11 answer is ignored and never
   applied, so startup cannot flash or retint after content appears.
2. **Never derive or query a palette for styling.** The app theme layer does
   not query OSC 4 or OSC 10 and does not blend a grayscale ramp from terminal
   RGB. OSC 11 answers only two things: which fixed set to use and which
   background to expose to an embedded fx terminal. Ignore color data from any
   independent UI-toolkit capability handshake.
3. **Replace the complete set live.** Enable mode 2031. Treat CSI 997 as a
   refresh trigger, fence a fresh OSC 11 sample with DA1 as fx does, then swap
   every role in one render turn. A newer notification invalidates an in-flight
   sample and starts a fresh fenced cycle. If `FX_THEME` is explicit, own the
   protocol replies but never query or change themes.
4. **Two ANSI intents, one job each.** `focus` is direct ANSI index 4: the
   border of a surface that takes keys, the row caret `▎`, and the prompt
   cursor. `error` is direct ANSI index 1: the border of a surface reporting
   failure. Do not sample, brighten, or replace these slots. Nothing else in
   fmx is chromatic; a new state gets a glyph and a weight, never a hue.
5. **Match the glyph vocabulary** where fmx shows the same concepts:
   Agent state glyphs borrowed from fx's tool vocabulary, `·` separators,
   prompt rails.
6. **State by shape and weight first**, color second — a colorblind-safe
   habit fx enforces by having almost no color at all.

The scrim behind a modal (`#00000033`) is the one opacity fmx uses: a 20%
darkening of whatever the stage is, not a color of its own.

## Artifacts and regeneration

| artifact | what | regenerate with |
|---|---|---|
| `style/tokens.json` | machine-readable tokens, keyed by role, with SGR + hex per theme | `scripts/style-extract.sh` |
| `style/captures/swatch-*.{ansi,txt}` | styled sample sheet of every token | `scripts/style-capture.sh --swatch-only` |
| `style/captures/fx-welcome-*.{png,txt}` | the real binary's welcome screen, both themes | `scripts/style-capture.sh` |
| `style/viewer/` | interactive visual guide (OpenTUI, same toolkit as fmx) | `scripts/style-view.sh` to open |

`scripts/style-extract.sh --check` diffs a fresh extraction against the
committed tokens.json and fails on drift — run it whenever the fx checkout
moves. See `MAINTAIN.md` § "Style guide".
