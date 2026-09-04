#!/usr/bin/env bun
// The fx style guide as a small OpenTUI app — a human-visible rendering of
// style/tokens.json. Everything painted here comes from the tokens (plus two
// simulated canvas colors, so both themes are inspectable from any terminal).
//
// Run via scripts/style-view.sh. Keys: 1-6 or arrows switch section,
// t toggles dark/light, q quits.
//
// @opentui/core is pinned to the version fmx uses, so what renders here is
// what fmx's own toolkit would produce from the same values.

import {
  BoxRenderable,
  CliRenderer,
  StyledText,
  TextRenderable,
  bold,
  fg,
  bg,
  italic,
  type KeyEvent,
  type TextChunk,
} from "@opentui/core"
import tokens from "../tokens.json"
import { CANVAS, FMX_ERROR, FMX_FOCUS, surface, type Theme, unused } from "./fmx-theme.ts"

type StyleValue = {
  seq: string
  bold: boolean
  fg: { hex: string; index?: number } | null
  bg: { hex: string; index?: number } | null
}

const SECTIONS = ["roles", "transcript", "code", "glyphs", "carve-outs", "about"] as const

const role = (name: string, theme: Theme): StyleValue =>
  (tokens.roles as Record<string, Record<Theme, StyleValue>>)[name][theme]

/** Paint text with an extracted style value, substituting the simulated
 * default foreground when the value carries no color of its own. */
function paint(value: StyleValue, text: string, theme: Theme): TextChunk {
  let chunk: TextChunk = fg(value.fg?.hex ?? role("hint", theme).fg!.hex)(text)
  if (value.bg) chunk = bg(value.bg.hex)(chunk)
  if (value.bold) chunk = bold(chunk)
  return chunk
}

function note(text: string, theme: Theme): TextChunk {
  return fg(role("dim", theme).fg!.hex)(text)
}

function annotate(value: StyleValue): string {
  const parts = []
  if (value.fg) parts.push(value.fg.hex + (value.fg.index !== undefined ? ` (${value.fg.index})` : ""))
  if (value.bg) parts.push(`on ${value.bg.hex}`)
  if (value.bold) parts.push("bold")
  return parts.join("  ") || "terminal default"
}

type Line = TextChunk[]

function rolesSection(theme: Theme): Line[] {
  const lines: Line[] = []
  lines.push([paint(role("tag", theme), "role tokens", theme), note("  src/ui/render.zig initTheme", theme)])
  lines.push([])
  for (const name of Object.keys(tokens.roles)) {
    const value = role(name, theme)
    lines.push([
      note(name.padEnd(26), theme),
      paint(value, "the quick brown fox", theme),
      note("  " + annotate(value), theme),
    ])
  }
  return lines
}

function transcriptSection(theme: Theme): Line[] {
  const t = theme
  const g = tokens.glyphs
  const added = tokens.diff_markers.added.truecolor as StyleValue
  const removed = tokens.diff_markers.removed.truecolor as StyleValue
  const rail = (tokens.user_card.rail_marker as Record<Theme, StyleValue>)[t]
  const accent = (tokens.user_card.accent as Record<Theme, StyleValue>)[t]
  const dimS = role("dim", t)
  const diffText = role("diff_added", t)
  const lines: Line[] = []
  lines.push([paint(role("tag", t), "a transcript, assembled from the tokens", t)])
  lines.push([])
  lines.push([paint(role("subtitle", t), "𝒇x", t), note(" v0.0.5 · Run /help for commands", t)])
  lines.push([])
  lines.push([paint(rail, g.user_turn_rail, t), paint(tokens.user_card.prompt_text as StyleValue, " fix the flaky test in ", t), paint(accent, "/review", t), paint(tokens.user_card.prompt_text as StyleValue, " please", t)])
  lines.push([])
  lines.push([paint(role("green", t), "●", t), paint({ seq: "", bold: true, fg: null, bg: null }, " Ran", t), note(" zig build test", t)])
  lines.push([note("  └ 312 pass · 0 fail · 4.1s", t)])
  lines.push([paint(role("green", t), "●", t), paint({ seq: "", bold: true, fg: null, bg: null }, " Edit", t), note(" src/ui/render.zig ", t), paint(added, "+1", t), note(" / ", t), paint(removed, "-1", t)])
  lines.push([paint(dimS, "  │ 41   fn hello() void {", t)])
  lines.push([paint(diffText, "  │ ", t), paint(removed, "42 -", t), paint(diffText, "     retrun old_name();", t)])
  lines.push([paint(diffText, "  │ ", t), paint(added, "42 +", t), paint(diffText, "     return new_name();", t)])
  lines.push([])
  lines.push([paint(role("divider", t), "─".repeat(46), t)])
  lines.push([paint(role("hint", t), tokens.glyphs.input_prefix, t), paint(role("hint", t), "█", t)])
  lines.push([paint(role("statusline", t), "~/source/vercel-labs--fx · integration · ", t), paint(role("permission_auto", t), "auto", t), paint(role("statusline", t), " · 45k", t)])
  lines.push([])
  lines.push([paint(role("approval_button_active", t), "  Yes  ", t), note("  ", t), paint(role("approval_button_inactive", t), "  No  ", t), note("   approval buttons", t)])
  return lines
}

function codeSection(theme: Theme): Line[] {
  const t = theme
  const hl = (slot: string) => (tokens.code_highlight as Record<Theme, Record<string, StyleValue>>)[t][slot]
  const inline = (tokens.assistant.inline_code as Record<Theme, StyleValue>)[t]
  const task = (tokens.assistant.task_completed as Record<Theme, StyleValue>)[t]
  const lines: Line[] = []
  lines.push([paint(role("tag", t), "code highlight", t), note("  four slots, still grayscale", t)])
  lines.push([])
  lines.push([paint(hl("comment"), "// retries until the gate settles", t)])
  lines.push([paint(hl("keyword"), "const", t), paint(role("hint", t), " limit = ", t), paint(hl("number"), "3", t), paint(role("hint", t), ";", t)])
  lines.push([paint(hl("keyword"), "if", t), paint(role("hint", t), " (status == ", t), paint(hl("string"), '"ready"', t), paint(role("hint", t), ") run();", t)])
  lines.push([])
  lines.push([paint(role("tag", t), "assistant text", t)])
  lines.push([])
  lines.push([paint(role("hint", t), "run ", t), paint(inline, "zig build", t), paint(role("hint", t), " before shipping", t), note("   inline code", t)])
  lines.push([paint(task, "✓", t), paint(role("hint", t), " focused tests pass", t), note("   completed task", t)])
  lines.push([])
  lines.push([paint(role("system_notice_label", t), "Notice", t), paint(role("system_notice_text", t), " compaction finished", t)])
  lines.push([])
  lines.push([paint(role("tag", t), "semantic states are one gray", t)])
  lines.push([])
  lines.push([paint(role("green", t), "green", t), note(" · ", t), paint(role("red", t), "red", t), note(" · ", t), paint(role("warning", t), "warning", t), note("   deliberately identical — glyphs carry state", t)])
  return lines
}

function glyphsSection(theme: Theme): Line[] {
  const t = theme
  const rows: Array<[string, string]> = [
    [tokens.glyphs.input_prefix.trim(), "input prompt prefix"],
    [tokens.glyphs.user_turn_rail, "user prompt rail"],
    ["●", "tool call — dim while running, accent when done"],
    ["■", "cancelled tool call"],
    ["├ └", "tool-group tree connectors"],
    ["│", "diff / code gutter"],
    ["·", "statusline separator"],
    ["⏺", "asking activity label"],
    ["✓", "completed task"],
  ]
  const lines: Line[] = []
  lines.push([paint(role("tag", t), "glyph vocabulary", t), note("  shape carries what color does not", t)])
  lines.push([])
  for (const [glyph, meaning] of rows) {
    lines.push([paint(role("hint", t), "  " + glyph.padEnd(5), t), note(meaning, t)])
  }
  lines.push([])
  lines.push([paint(role("tag", t), "typography", t)])
  lines.push([])
  lines.push([bold(paint(role("hint", t), "bold", t)), note(" labels, titles, prompts, the selected row", t)])
  lines.push([bold(italic(paint(role("hint", t), "bold italic", t))), note(" tool-group summaries", t)])
  lines.push([note("no underline except hyperlinks · no emoji, Unicode symbols fine", t)])
  return lines
}

/** The carve-outs: surfaces fx never draws, built from its fixed tokens plus
 * fmx's indexed additions. Not extracted — see STYLE.md "Carve-outs". */
function carveOutsSection(theme: Theme): Line[] {
  const t = theme
  const lines: Line[] = []
  const heading = (title: string, why: string): Line => [paint(role("system_notice_label", t), title, t), note("  " + why, t)]
  lines.push([paint(role("tag", t), "carve-outs", t), note("  surfaces fx never draws, using the same fixed dark/light sets", t)])
  lines.push([])

  // 1. A larger observing Client around a smaller sizing-owner frame.
  lines.push(heading("unused space around a smaller sizing owner", "one flat theme step — no boundary or texture"))
  const ownerWidth = 46
  const unusedWidth = 14
  const unusedFill = (width: number): TextChunk => bg(unused(t))(note(" ".repeat(width), t))
  const ownerLine = (chunks: Line, used: number): Line => [
    ...chunks.map((chunk) => bg(CANVAS[t])(chunk)),
    bg(CANVAS[t])(note(" ".repeat(Math.max(0, ownerWidth - used)), t)),
    unusedFill(unusedWidth),
  ]
  lines.push(ownerLine([
    bold(paint(role("hint", t), " fmx", t)),
    note("             ", t),
    paint(role("hint", t), "Working on the UI gallery", t),
  ], 42))
  lines.push(ownerLine([
    bold(paint(role("hint", t), "   main", t)),
    note("          ", t),
    paint(role("permission_auto", t), "✓ ", t),
    paint(role("dim", t), "Inventory visible", t),
  ], 36))
  lines.push(ownerLine([
    paint(role("dim", t), "     ◐ Review UI", t),
    note(" ", t),
    paint(role("dim", t), "◐ Review the gallery", t),
  ], 37))
  lines.push(ownerLine([
    note("                 ", t),
    paint(role("dim", t), "Deterministic state.", t),
  ], 37))
  lines.push([unusedFill(ownerWidth + unusedWidth)])
  lines.push([unusedFill(ownerWidth + unusedWidth)])
  lines.push([])

  // 2. Agent rows in the tray: state by glyph and weight.
  lines.push(heading("agent rows in the tray", "labels primary, names dim, the glyph carries the state — never a hue"))
  const name = (text: string) => paint(role("dim", t), text, t)
  const fill = (chunk: TextChunk) => bg(surface(t))(chunk)
  const annotate = (used: number, text: string): TextChunk => note(" ".repeat(Math.max(2, 34 - used)) + text, t)
  lines.push([paint(role("hint", t), " fmx", t)])
  lines.push([bold(paint(role("hint", t), "   main", t)), annotate(7, "bold: on the path to the active agent")])
  lines.push([bold(paint(role("hint", t), "     × ", t)), name("needs-permission"), annotate(23, "blocked — bold primary, what needs you")])
  lines.push([
    fill(paint(role("dim", t), "     ◐ ", t)),
    fill(name("implement-gallery")),
    fill(note("   ", t)),
    annotate(27, "active — the surface fill; working — dim"),
  ])
  lines.push([paint(role("permission_auto", t), "     ✓ ", t), name("review-complete"), annotate(22, "done — accent, one step brighter than its row")])
  lines.push([paint(role("dim", t), "     ○ ", t), name("available"), annotate(16, "idle — dim")])
  lines.push([italic(paint(role("system_notice_text", t), "   (untracked)", t)), annotate(14, "virtual branch — secondary, italic, never bold")])
  lines.push([paint(role("dim", t), "     · ", t), name("starting"), annotate(15, "unknown — dim")])
  lines.push([])

  // 3. Surfaces over the stage: focus marks keys and error marks failure.
  lines.push(heading("surfaces over the stage", "focus border takes keys · error border reports failure"))
  const F = (text: string) => fg(FMX_FOCUS)(text)
  const E = (text: string) => fg(FMX_ERROR)(text)
  const D = (text: string) => paint(role("dim", t), text, t)
  const label = (text: string) => paint(role("system_notice_text", t), text, t)
  const value = (text: string) => paint(role("hint", t), text, t)
  const inner = 38
  const pad = (used: number) => " ".repeat(Math.max(0, inner - used))
  lines.push([F(" ┌─ "), value("launch"), F(" " + "─".repeat(inner - 8) + "┐"), note("   title primary; rows: label secondary, value primary", t)])
  lines.push([F(" │ "), bold(F("▎ ")), label("prompt    "), D("what should the agent do?"), value(pad(37)), F("│"), note("   ▎ focus caret; placeholder dim", t)])
  lines.push([F(" │ "), value("  "), label("project   "), value("~/code/fmx"), value(pad(22)), F("│")])
  lines.push([F(" │ "), value("  "), label("worktree  "), value("no"), value(pad(14)), F("│")])
  lines.push([F(" └" + "─".repeat(inner + 1) + "┘")])
  lines.push([E(" ┌─ "), value("error"), E(" ────────────┐"), note("   a failure: ANSI 1 on the border, heading bold accent", t)])
  lines.push([E(" │ "), bold(paint(role("red", t), "fx did not start", t)), value("   "), E("│")])
  lines.push([E(" └" + "─".repeat(20) + "┘")])
  lines.push([])

  lines.push([note("no hue for a state, no underline; every role is fixed for the selected fxnk theme", t)])
  return lines
}

function aboutSection(theme: Theme): Line[] {
  const t = theme
  const gen = tokens.generated
  const lines: Line[] = []
  lines.push([paint(role("tag", t), "about this guide", t)])
  lines.push([])
  lines.push([note("every color here is extracted from fx — ", t), paint(role("hint", t), `${gen.fx_ref} ${gen.fx_commit.slice(0, 7)}`, t)])
  lines.push([note("the two canvas backgrounds are simulated; fx inherits the terminal's", t)])
  lines.push([])
  lines.push([note("ground truth   style/tokens.json (scripts/style-extract.sh)", t)])
  lines.push([note("prose          style/STYLE.md", t)])
  lines.push([note("methodology    MAINTAIN.md § Style guide", t)])
  lines.push([])
  lines.push([note("drift gate     scripts/style-extract.sh --check", t)])
  lines.push([note("captures       scripts/style-capture.sh", t)])
  lines.push([])
  lines.push([paint(role("system_notice_label", t), "the retint constraint", t)])
  lines.push([note("fx live-switches themes by byte substitution over six token pairs —", t)])
  lines.push([note("write only ramp values, or a live switch strands your bytes dark", t)])
  return lines
}

function buildSection(section: (typeof SECTIONS)[number], theme: Theme): StyledText {
  const builders = {
    roles: rolesSection,
    transcript: transcriptSection,
    code: codeSection,
    glyphs: glyphsSection,
    "carve-outs": carveOutsSection,
    about: aboutSection,
  }
  const lines = builders[section](theme)
  const chunks: TextChunk[] = []
  lines.forEach((line, i) => {
    if (i > 0) chunks.push(fg(CANVAS[theme] === "#121212" ? "#eeeeee" : "#262626")("\n"))
    if (line.length === 0) chunks.push(fg(role("dim", theme).fg!.hex)(" "))
    else chunks.push(...line)
  })
  return new StyledText(chunks)
}

function footer(section: (typeof SECTIONS)[number], theme: Theme): StyledText {
  const chunks: TextChunk[] = []
  SECTIONS.forEach((name, i) => {
    if (i > 0) chunks.push(note(" · ", theme))
    const label = `${i + 1} ${name}`
    chunks.push(section === name ? paint(role("permission_auto", theme), label, theme) : note(label, theme))
  })
  chunks.push(note("      t theme · ←/→ section · q quit", theme))
  return new StyledText(chunks)
}

async function main(): Promise<void> {
  let theme: Theme = Bun.argv.includes("--theme") ? ((Bun.argv[Bun.argv.indexOf("--theme") + 1] as Theme) ?? "dark") : "dark"
  if (theme !== "dark" && theme !== "light") theme = "dark"
  let section: (typeof SECTIONS)[number] = "transcript"

  const renderer = new CliRenderer(
    process.stdin,
    process.stdout,
    process.stdout.columns || 80,
    process.stdout.rows || 24,
    { exitOnCtrlC: false, exitSignals: [] },
  )
  await renderer.setupTerminal()

  const root = new BoxRenderable(renderer, {
    id: "styleguide-root",
    width: "100%",
    height: "100%",
    flexDirection: "column",
    paddingX: 2,
    paddingY: 1,
    backgroundColor: CANVAS[theme],
  })
  const header = new TextRenderable(renderer, { id: "styleguide-header", height: 1, selectable: false })
  const spacer = new TextRenderable(renderer, { id: "styleguide-spacer", height: 1, content: " ", selectable: false })
  const body = new TextRenderable(renderer, { id: "styleguide-body", flexGrow: 1, selectable: false })
  const foot = new TextRenderable(renderer, { id: "styleguide-footer", height: 1, selectable: false })
  root.add(header)
  root.add(spacer)
  root.add(body)
  root.add(foot)
  renderer.root.add(root)

  const repaint = () => {
    root.backgroundColor = CANVAS[theme]
    header.content = new StyledText([
      paint(role("subtitle", theme), "𝒇x style guide", theme),
      note(` · ${theme} · fx ${tokens.generated.fx_commit.slice(0, 7)}`, theme),
    ])
    body.content = buildSection(section, theme)
    foot.content = footer(section, theme)
  }
  repaint()

  let done: () => void = () => {}
  const finished = new Promise<void>((resolve) => {
    done = resolve
  })

  renderer.keyInput.on("keypress", (key: KeyEvent) => {
    const name = key.name?.toLowerCase() ?? ""
    if (name === "q" || name === "escape" || (key.ctrl && name === "c")) {
      done()
      return
    }
    if (name === "t") {
      theme = theme === "dark" ? "light" : "dark"
      repaint()
      return
    }
    if (name === "left" || name === "h") {
      section = SECTIONS[(SECTIONS.indexOf(section) + SECTIONS.length - 1) % SECTIONS.length]!
      repaint()
      return
    }
    if (name === "right" || name === "l") {
      section = SECTIONS[(SECTIONS.indexOf(section) + 1) % SECTIONS.length]!
      repaint()
      return
    }
    const digit = Number.parseInt(name, 10)
    if (digit >= 1 && digit <= SECTIONS.length) {
      section = SECTIONS[digit - 1]!
      repaint()
    }
  })

  renderer.start()
  await finished
  renderer.destroy()
}

await main()
