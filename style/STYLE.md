# The fx style guide, for fmx

fx is the living style guide for fmx: whenever fmx draws its own chrome —
modals, toasts, panels, status rows — it should look like it belongs in the
same instrument as the fx it embeds. This document extracts fx's visual
language into rules and values fmx developers can borrow directly.

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

## Carve-outs: what fx has no surface for

fx is a transcript with a prompt; it has no tabs, no docks, no switcher. When
fmx needs a surface fx never draws, the rule is to build it from fx's
principles — one ramp, weight and glyph for state, no hue, no underline —
and record it here as a carve-out. Nothing below is extracted from fx:
`tokens.json` does not carry it, `style-extract.sh --check` cannot see it,
and a maintenance cycle must not "correct" it back to fx.

### Unused space around a smaller sizing owner

fmx renders one shared Runtime at the dimensions of the Client that most
recently connected or interacted. When another Client's physical terminal is
larger than that sizing-owner frame, its extra cells on the right and bottom
are neither another pane nor a navigable viewport. They are one flat
**unused field** behind the shared frame at the top left.

| part | dark host | light host |
|---|---|---|
| shared frame | the host background | the host background |
| unused field | host background mixed 6% toward its foreground — lighter than the frame, below every surface | host background mixed 6% toward its foreground — darker than the frame, above every surface |

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
mark made unused space compete with the work. A theme-relative flat field is
visible without becoming content of its own.

### Switching items in a panel: the rule tab

The Tools panel's switcher (`fmx/src/tool-panel.ts`) is a **rule tab**: one
row of labels over one row of hairline.

```
 Diff  Tests  Logs
───────━━━━━───────────────
```

| part | role | dark | light |
|---|---|---|---|
| selected label | `selected_completion` (bold primary) | bold 255 | bold 235 |
| other labels | `dim` | 245 | 247 |
| rule under the selection | `hint` (primary), glyph `━` | 255 | 235 |
| rule elsewhere | `divider`, glyph `─` | 240 | 250 |

Why this shape and not another: the divider glyph does the underlining, so
the no-underline rule holds; the selection is bold like fx's selected menu
row; nothing in it takes the accent hue, which fmx keeps for focus and
failure. In fmx the values are host-derived per "Borrowing into fmx" —
`hostRamp().foreground`, `.dim`, and `.divider` — and the column above is
the no-answer fallback tier. Other shapes considered and not taken: weighted
words with `·` separators (fx's statusline idiom, but reads as status rather
than a control), an inverse chip (fx's button idiom, too loud for a
persistent dock), a cycler (hides the other items).

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
| active row | surface fill, 12% from the background toward the foreground — fmx's own step below `divider` | — | — |

Why this shape: fx marks a running tool call dim and a finished one accent,
which is exactly the working/done pair; blocked takes the brightest gray and
bold because in fx's language "what matters now" is the only thing allowed
to be loud. The fill rather than inversion or bold for the active row: bold
is already the path, and fx's inverse-video button is far too loud for a
row that is on screen all day. Before the host palette answers, names are
the terminal's own ANSI gray (slot 8, dim on any theme) so the first frame
needs no guess; afterwards they are `dim`. Not taken: the five ANSI status
hues fmx used before this guide (red/yellow/cyan/green/gray — state by hue,
which fx forbids), and a host-red "attention" exception for blocked (one
more hue than fx spends, and the bold glyph already reads first).

### Surfaces over the stage

fx has no modal, dialog, picker, or toast; its prompts are inline. fmx's
help modal and spawn error (`fmx/src/multiplexer.ts`), launch dialog and
project/model pickers (`fmx/src/launch-dialog.ts`), and toast
(`fmx/src/toast.ts`) are one family: a bordered body over a dimmed stage.

```
┌─ launch ─────────────────────────────┐
│ ▎ prompt    what should the agent do?│      focus border: this takes keys
│   project   ~/code/fmx               │
│   worktree  no                       │
└──────────────────────────────────────┘
        ┌────────────────────────┐
        │ fmx / main / agent 3 started │        dim hairline: this takes none
        └────────────────────────┘
```

| part | role | dark | light |
|---|---|---|---|
| scrim behind a modal or dialog | `#00000033` — a 20% black darkening, fmx's one opacity; not a hue, and reads as a dimmed stage on either theme | — | — |
| body | the host background (modal, dialog, picker); the surface fill (toast, lifted off the stage) | — | — |
| border, surface that takes keys | **focus** — the host's blue, fmx's own; fallback `#7dd3fc` | — | — |
| border, surface that takes no keys (toast) | `dim` | 245 | 247 |
| border, surface reporting a failure | **error** — the host's red; fallback fx's `#e5484d` | — | — |
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
keys wears it on its border and nowhere else takes it; the toast takes no
keys and gets the hairline instead. The picker is fx's completion menu
(selected row bold primary). The help modal's key/description pairs and
the dialog's label/value pairs are fx's notice-label/notice-text pairing.
Not taken: a green success toast (fx's `green` is gray; "started" is in the
words), red text inside the error modal (the border already says failure;
one red per surface), bold titles (OpenTUI box titles take a color only).

## Borrowing into fmx

fmx's own surfaces derive from the host terminal's palette
(`fmx/src/host-palette.ts`, `hostRamp`), which is *more* faithful to the
shared principle than fx's fixed grays. So the rule is not "copy the hex":

1. **Reproduce the ramp as relationships.** fx's five steps become
   fractions of the way from the host's background to its foreground. The
   ratios are read off tokens.json (dark 255/252/250/245/240 on a
   near-black canvas, light 235/238/241/247/250 on a near-white one), and
   fmx adds two steps below the divider: a raised surface fill for the active
   tray row and toast body, then a quieter unused-field fill between that
   surface and the terminal background.

   | ramp step | fx role | fraction bg → fg | fallback |
   |---|---|---|---|
   | foreground | `hint`, `tag` (primary) | the host foreground | 255 `#eeeeee` |
   | accent | `warning`/`green`/`red`, `system_notice_label`, `permission_auto` | 0.85 | 252 `#d0d0d0` |
   | secondary | `system_notice_text` | 0.75 | 250 `#bcbcbc` |
   | dim | `dim`, `statusline` | 0.5 | 245 `#8a8a8a` |
   | divider | `divider` | 0.3 | 240 `#585858` |
   | surface | — (fmx's fill) | 0.12 | `#353535` |
   | unused | — (fmx's unused Client field) | 0.06 | `#292929` |
   | background | the terminal's | the host background | 234 `#1c1c1c` |

2. **The fallback tier preserves fx's dark column exactly.** A host that
   answers no color query gets fx's shared ramp values verbatim; fmx's two
   fill steps are derived from that column's background and foreground at
   their listed ratios. On any real canvas the blends land within a step of
   it. A host that answers only its background gets fx's light or dark primary
   by that background's brightness.
3. **Two hues, one job each.** `focus` is the host's blue (ANSI 4, then
   12; fallback `#7dd3fc`): the border of a surface that takes keys, the
   row caret `▎`, the prompt cursor. `error` is the host's red (ANSI 1,
   then 9; fallback fx's own `#e5484d`): the border of a surface that
   reports a failure. Nothing else in fmx is chromatic. A new state gets a
   glyph and a weight, never a hue.
4. **Match the glyph vocabulary** where fmx shows the same concepts:
   agent/tool state glyphs, `·` separators, prompt rails.
5. **State by shape and weight first**, color second — a colorblind-safe
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
