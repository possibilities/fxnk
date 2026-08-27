#!/usr/bin/env bun
// A full-screen OpenTUI lab for comparing ways fmx could express its
// momentary prefix-key state. This is a prototype, not the fmx implementation:
// the actions are real enough to exercise but deliberately have no side
// effects. It renders from fxnk's extracted grayscale ramp plus the shared
// fixed fmx carve-outs for focus, lifted surfaces, and the 20% black scrim.

import {
  BoxRenderable,
  CliRenderEvents,
  CliRenderer,
  StyledText,
  TextRenderable,
  bg,
  bold,
  fg,
  type ColorInput,
  type KeyEvent,
  type MouseEvent,
  type TextChunk,
} from "@opentui/core"
import tokens from "../tokens.json"
import { CANVAS, FMX_FOCUS, FMX_SCRIM, surface, type Theme } from "./fmx-theme.ts"

export type { Theme } from "./fmx-theme.ts"

type StyleValue = {
  seq: string
  bold: boolean
  fg: { hex: string; index?: number } | null
  bg: { hex: string; index?: number } | null
}

type Treatment = {
  name: string
}

type PrefixAction = {
  key: string
  label: string
}

export type PrefixModeLabOptions = {
  theme?: Theme
  treatment?: number
  reducedMotion?: boolean
  showIntro?: boolean
}

const OPAQUE_SPACE = "\u00a0"

export const TREATMENTS: readonly Treatment[] = [
  { name: "control rail" },
  { name: "ghost chord" },
  { name: "chord compass" },
  { name: "signal sweep" },
  { name: "aperture" },
  { name: "key field" },
] as const

export const PREFIX_ACTIONS: readonly PrefixAction[] = [
  { key: "?", label: "keybinds" },
  { key: "d", label: "detach client" },
  { key: "p", label: "prev agent" },
  { key: "n", label: "next agent" },
  { key: "b", label: "toggle tray" },
] as const

const BIG_FONT: Readonly<Record<string, readonly string[]>> = {
  " ": ["   ", "   ", "   ", "   ", "   "],
  "?": ["███", "  █", " ██", "   ", " █ "],
  B: ["████ ", "█   █", "████ ", "█   █", "████ "],
  C: [" ████", "█    ", "█    ", "█    ", " ████"],
  D: ["███ ", "█  █", "█  █", "█  █", "███ "],
  L: ["█    ", "█    ", "█    ", "█    ", "█████"],
  N: ["█   █", "██  █", "█ █ █", "█  ██", "█   █"],
  P: ["████ ", "█   █", "████ ", "█    ", "█    "],
  R: ["████ ", "█   █", "████ ", "█  █ ", "█   █"],
  T: ["█████", "  █  ", "  █  ", "  █  ", "  █  "],
}

const role = (name: string, theme: Theme): StyleValue =>
  (tokens.roles as Record<string, Record<Theme, StyleValue>>)[name]![theme]!

function paint(value: StyleValue, text: string, theme: Theme): TextChunk {
  let chunk: TextChunk = fg(value.fg?.hex ?? role("hint", theme).fg!.hex)(text)
  if (value.bg) chunk = bg(value.bg.hex)(chunk)
  if (value.bold) chunk = bold(chunk)
  return chunk
}

function primary(text: string, theme: Theme): TextChunk {
  return paint(role("hint", theme), text, theme)
}

function secondary(text: string, theme: Theme): TextChunk {
  return paint(role("system_notice_text", theme), text, theme)
}

function note(text: string, theme: Theme): TextChunk {
  return paint(role("dim", theme), text, theme)
}

function rule(text: string, theme: Theme): TextChunk {
  return paint(role("divider", theme), text, theme)
}

function label(text: string, theme: Theme): TextChunk {
  return paint(role("system_notice_label", theme), text, theme)
}

function linesToStyled(lines: TextChunk[][], theme: Theme): StyledText {
  const chunks: TextChunk[] = []
  lines.forEach((line, index) => {
    if (index > 0) chunks.push(primary("\n", theme))
    if (line.length === 0) chunks.push(note(" ", theme))
    else chunks.push(...line)
  })
  return new StyledText(chunks)
}

function renderBig(text: string): string {
  const rows = Array.from({ length: 5 }, () => "")
  for (const character of text.toUpperCase()) {
    const glyph = BIG_FONT[character] ?? BIG_FONT[" "]!
    for (let row = 0; row < rows.length; row++) {
      rows[row] += `${glyph[row]} `
    }
  }
  return rows.map((row) => row.trimEnd()).join("\n")
}

function textSize(content: string): { width: number; height: number } {
  const lines = content.split("\n")
  return {
    width: Math.max(1, ...lines.map((line) => [...line].length)),
    height: lines.length,
  }
}

function solidFill(width: number, height: number, color: ColorInput, theme: Theme): StyledText {
  const chunks: TextChunk[] = []
  for (let row = 0; row < height; row++) {
    if (row > 0) chunks.push(primary("\n", theme))
    // OpenTUI intentionally lets an ordinary space preserve the glyph below
    // it while blending only its background. A non-breaking space is still a
    // blank cell, but has a glyph identity and therefore makes the lifted
    // field genuinely opaque.
    chunks.push(bg(color)(fg(color)(OPAQUE_SPACE.repeat(width))))
  }
  return new StyledText(chunks)
}

function textOnSurface(
  text: string,
  width: number,
  theme: Theme,
  ink: (character: string, theme: Theme) => TextChunk,
): StyledText {
  const chunks: TextChunk[] = []
  text.split("\n").forEach((line, row) => {
    if (row > 0) chunks.push(primary("\n", theme))
    for (const character of line.padEnd(width).slice(0, width)) {
      chunks.push(character === " " ? bg(surface(theme))(fg(surface(theme))(OPAQUE_SPACE)) : ink(character, theme))
    }
  })
  return new StyledText(chunks)
}

function isCtrl(key: KeyEvent, name: string): boolean {
  return key.ctrl && (key.name?.toLowerCase() ?? "") === name
}

function secondStroke(key: KeyEvent): string | null {
  const name = key.name?.toLowerCase() ?? ""
  if (name === "?" || (name === "/" && key.shift)) return "?"
  if (key.sequence === "?") return "?"
  if (name.length === 1 && !key.ctrl && !key.meta && !key.option && !key.super && !key.hyper) return name
  if (key.sequence?.length === 1 && !key.ctrl && !key.meta && !key.option && !key.super && !key.hyper) {
    return key.sequence.toLowerCase()
  }
  return null
}

function normalizeTreatment(value: number | undefined): number {
  if (!Number.isFinite(value)) return 0
  return Math.max(0, Math.min(TREATMENTS.length - 1, Math.floor(value!)))
}

export class PrefixModeLab {
  readonly finished: Promise<void>

  private readonly root: BoxRenderable
  private readonly stage: BoxRenderable
  private readonly tray: BoxRenderable
  private readonly trayText: TextRenderable
  private readonly divider: BoxRenderable
  private readonly content: BoxRenderable
  private readonly transcript: TextRenderable
  private readonly scrim: BoxRenderable
  private readonly overlay: BoxRenderable
  private readonly toast: BoxRenderable
  private readonly toastText: TextRenderable
  private readonly reducedMotion: boolean
  private theme: Theme
  private treatment: number
  private armed = false
  private pulsePhase = 6
  private pulseTimer: ReturnType<typeof setInterval> | null = null
  private toastTimer: ReturnType<typeof setTimeout> | null = null
  private done = false
  private resolveFinished!: () => void

  private readonly keyHandler = (key: KeyEvent) => this.onKeyPress(key)
  private readonly resizeHandler = () => this.repaint()

  constructor(
    private readonly renderer: CliRenderer,
    options: PrefixModeLabOptions = {},
  ) {
    this.theme = options.theme ?? "dark"
    this.treatment = normalizeTreatment(options.treatment)
    this.reducedMotion = options.reducedMotion ?? false
    this.finished = new Promise<void>((resolve) => {
      this.resolveFinished = resolve
    })

    this.root = new BoxRenderable(renderer, {
      id: "prefix-lab-root",
      width: "100%",
      height: "100%",
      backgroundColor: CANVAS[this.theme],
    })
    this.stage = new BoxRenderable(renderer, {
      id: "prefix-lab-stage",
      width: "100%",
      height: "100%",
      flexDirection: "row",
      backgroundColor: CANVAS[this.theme],
    })
    this.tray = new BoxRenderable(renderer, {
      id: "prefix-lab-tray",
      width: 27,
      height: "100%",
      flexShrink: 0,
      backgroundColor: CANVAS[this.theme],
    })
    this.trayText = new TextRenderable(renderer, {
      id: "prefix-lab-tray-text",
      width: "100%",
      height: "100%",
      paddingX: 2,
      paddingY: 2,
      selectable: false,
      wrapMode: "none",
      truncate: true,
    })
    this.divider = new BoxRenderable(renderer, {
      id: "prefix-lab-divider",
      width: 1,
      height: "100%",
      flexShrink: 0,
      border: ["left"],
      borderStyle: "single",
    })
    this.content = new BoxRenderable(renderer, {
      id: "prefix-lab-content",
      flexGrow: 1,
      flexShrink: 1,
      height: "100%",
      backgroundColor: CANVAS[this.theme],
    })
    this.transcript = new TextRenderable(renderer, {
      id: "prefix-lab-transcript",
      width: "100%",
      height: "100%",
      paddingX: 3,
      paddingY: 2,
      selectable: false,
      wrapMode: "none",
      truncate: true,
    })
    this.tray.add(this.trayText)
    this.content.add(this.transcript)
    this.stage.add(this.tray)
    this.stage.add(this.divider)
    this.stage.add(this.content)

    this.scrim = new BoxRenderable(renderer, {
      id: "prefix-lab-scrim",
      position: "absolute",
      top: 0,
      left: 0,
      width: "100%",
      height: "100%",
      zIndex: 20,
      backgroundColor: FMX_SCRIM,
      visible: false,
      onMouseDown: () => this.cancelPrefix(),
    })
    this.overlay = new BoxRenderable(renderer, {
      id: "prefix-lab-overlay",
      position: "absolute",
      top: 0,
      left: 0,
      width: "100%",
      height: "100%",
      zIndex: 30,
      backgroundColor: "#00000000",
      shouldFill: false,
      visible: false,
    })
    this.toast = new BoxRenderable(renderer, {
      id: "prefix-lab-toast",
      position: "absolute",
      top: 1,
      right: 2,
      width: 34,
      height: 3,
      paddingX: 1,
      border: ["left"],
      borderStyle: "single",
      zIndex: 100,
      visible: false,
    })
    this.toastText = new TextRenderable(renderer, {
      id: "prefix-lab-toast-text",
      width: "100%",
      height: 1,
      selectable: false,
      truncate: true,
    })
    this.toast.add(this.toastText)

    this.root.add(this.stage)
    this.root.add(this.scrim)
    this.root.add(this.overlay)
    this.root.add(this.toast)
    renderer.root.add(this.root)
    renderer.keyInput.on("keypress", this.keyHandler)
    renderer.on(CliRenderEvents.RESIZE, this.resizeHandler)
    this.repaint()

    if (options.showIntro !== false) {
      this.showToast("ctrl+b arm · 1–6 choose · t theme · q quit", 4200)
    }
  }

  get activeTreatment(): number {
    return this.treatment
  }

  get prefixArmed(): boolean {
    return this.armed
  }

  destroy(): void {
    this.clearTimers()
    this.renderer.keyInput.off("keypress", this.keyHandler)
    this.renderer.off(CliRenderEvents.RESIZE, this.resizeHandler)
    this.renderer.root.remove(this.root)
    this.root.destroyRecursively()
  }

  private clearTimers(): void {
    if (this.pulseTimer) clearInterval(this.pulseTimer)
    if (this.toastTimer) clearTimeout(this.toastTimer)
    this.pulseTimer = null
    this.toastTimer = null
  }

  private finish(): void {
    if (this.done) return
    this.done = true
    this.clearTimers()
    this.resolveFinished()
  }

  private onKeyPress(key: KeyEvent): void {
    if (isCtrl(key, "c")) {
      this.finish()
      return
    }

    const name = key.name?.toLowerCase() ?? ""
    if (this.armed) {
      if (name === "escape" || isCtrl(key, "b")) {
        this.cancelPrefix()
        return
      }
      const stroke = secondStroke(key)
      if (stroke === null) return
      const action = PREFIX_ACTIONS.find((candidate) => candidate.key === stroke)
      if (action) this.runAction(action)
      else {
        this.cancelPrefix()
        this.showToast(`unbound ${stroke} · prefix cancelled`, 1100)
      }
      return
    }

    if (isCtrl(key, "b")) {
      this.armPrefix()
      return
    }
    if (name === "q" || name === "escape") {
      this.finish()
      return
    }
    if (name === "t") {
      this.theme = this.theme === "dark" ? "light" : "dark"
      this.repaint()
      this.showToast(`${this.theme} theme`, 850)
      return
    }
    const digit = Number.parseInt(name, 10)
    if (digit >= 1 && digit <= TREATMENTS.length) {
      this.selectTreatment(digit - 1)
      return
    }
    if (name === "left" || name === "h") {
      this.selectTreatment((this.treatment + TREATMENTS.length - 1) % TREATMENTS.length)
      return
    }
    if (name === "right" || name === "l" || name === "tab") {
      this.selectTreatment((this.treatment + 1) % TREATMENTS.length)
    }
  }

  private selectTreatment(index: number): void {
    this.treatment = normalizeTreatment(index)
    this.repaint()
    this.showToast(`${this.treatment + 1} · ${TREATMENTS[this.treatment]!.name}`, 1000)
  }

  private armPrefix(): void {
    this.armed = true
    this.pulsePhase = this.reducedMotion ? 6 : 0
    this.startPulse()
    this.repaint()
  }

  private cancelPrefix(): void {
    if (!this.armed) return
    this.armed = false
    if (this.pulseTimer) clearInterval(this.pulseTimer)
    this.pulseTimer = null
    this.repaint()
  }

  private startPulse(): void {
    if (this.reducedMotion || this.treatment !== 3) return
    if (this.pulseTimer) clearInterval(this.pulseTimer)
    this.pulseTimer = setInterval(() => {
      this.pulsePhase++
      if (this.pulsePhase >= 6 && this.pulseTimer) {
        clearInterval(this.pulseTimer)
        this.pulseTimer = null
      }
      this.repaintOverlay()
    }, 55)
  }

  private runAction(action: PrefixAction): void {
    this.cancelPrefix()
    this.showToast(`${action.label} · demo only`, 1200)
  }

  private showToast(message: string, durationMs: number): void {
    if (this.toastTimer) clearTimeout(this.toastTimer)
    this.toastText.content = new StyledText([primary(message, this.theme)])
    this.toast.width = Math.min(Math.max(18, [...message].length + 4), Math.max(18, this.renderer.width - 4))
    this.toast.visible = true
    this.toastTimer = setTimeout(() => {
      this.toast.visible = false
      this.toastTimer = null
    }, durationMs)
  }

  private repaint(): void {
    const t = this.theme
    const narrow = this.renderer.width < 62
    this.root.backgroundColor = CANVAS[t]
    this.stage.backgroundColor = CANVAS[t]
    this.tray.backgroundColor = CANVAS[t]
    this.content.backgroundColor = CANVAS[t]
    this.tray.visible = !narrow
    this.divider.visible = !narrow
    this.divider.borderColor = role("divider", t).fg!.hex
    this.trayText.content = this.trayContent()
    this.transcript.content = this.transcriptContent(narrow)
    this.toast.backgroundColor = surface(t)
    this.toast.borderColor = role("dim", t).fg!.hex
    this.repaintOverlay()
  }

  private trayContent(): StyledText {
    const t = this.theme
    const active = (text: string): TextChunk => bg(surface(t))(note(text, t))
    return linesToStyled(
      [
        [bold(primary("fmx", t))],
        [],
        [bold(primary("main", t))],
        [active("  ◐ prefix-mode-lab   ")],
        [paint(role("permission_auto", t), "  ✓ ", t), note("trace-repaint", t)],
        [note("  ○ keybinding-notes", t)],
        [],
        [secondary("experiments", t)],
        [note("  ◐ compare-overlays", t)],
        [note("  · try-narrow-width", t)],
      ],
      t,
    )
  }

  private transcriptContent(narrow: boolean): StyledText {
    const t = this.theme
    const width = Math.max(24, this.renderer.width - (narrow ? 7 : 34))
    const divider = "─".repeat(Math.min(58, width))
    const lines: TextChunk[][] = [
      [paint(role("subtitle", t), "𝒇x", t), note(" v0.0.6 · Run /help for commands", t)],
      [],
      [
        paint((tokens.user_card.rail_marker as Record<Theme, StyleValue>)[t]!, "┃", t),
        bold(primary(" make prefix mode impossible to miss", t)),
      ],
      [],
      [paint(role("green", t), "●", t), bold(primary(" Read", t)), note(" fxnk's visual language", t)],
      [note("  └ one ramp · shape before color · focus owns blue", t)],
      [paint(role("green", t), "●", t), bold(primary(" Mapped", t)), note(" the real fmx prefix actions", t)],
      [note("  └ ? keybinds · d detach · p/n agents · b tray", t)],
      [],
      [primary("The prefix chord is captured. The next key belongs to fmx,", t)],
      [primary("not the embedded agent. The treatment should make that state", t)],
      [primary("obvious without becoming permanent chrome.", t)],
      [],
      [rule(divider, t)],
      [primary(tokens.glyphs.input_prefix, t), primary("█", t)],
      [
        paint(role("statusline", t), "~/code/fmx · main · ", t),
        paint(role("permission_auto", t), "auto", t),
        paint(role("statusline", t), " · 45k", t),
      ],
    ]
    if (narrow) {
      lines.splice(6, 6, [note("  └ ctrl+b then ? / d / p / n / b", t)])
    }
    return linesToStyled(lines, t)
  }

  private repaintOverlay(): void {
    for (const child of [...this.overlay.getChildren()]) {
      this.overlay.remove(child)
      child.destroyRecursively()
    }

    this.overlay.visible = this.armed
    this.scrim.visible = this.armed && this.treatment !== 0
    if (!this.armed) return

    this.addOverlayLabel()
    switch (this.treatment) {
      case 0:
        this.renderControlRail()
        break
      case 1:
        this.renderGhostChord()
        break
      case 2:
        this.renderCompass()
        break
      case 3:
        this.renderSignalSweep()
        break
      case 4:
        this.renderAperture()
        break
      case 5:
        this.renderKeyField()
        break
    }
  }

  private addOverlayLabel(): void {
    const t = this.theme
    const treatment = TREATMENTS[this.treatment]!
    this.addText(2, 1, new StyledText([label("prefix", t), note(` · ${treatment.name}`, t)]))
    const cancel = "esc cancel"
    this.addText(Math.max(2, this.renderer.width - cancel.length - 3), 1, new StyledText([note(cancel, t)]))
  }

  private renderControlRail(): void {
    const t = this.theme
    const height = Math.min(4, this.renderer.height)
    const rail = this.addBox(0, Math.max(0, this.renderer.height - height), this.renderer.width, height, {
      backgroundColor: CANVAS[t],
      border: ["top"],
      borderColor: FMX_FOCUS,
    })
    const available = Math.max(1, this.renderer.width - 4)
    let x = 2
    for (const action of PREFIX_ACTIONS) {
      const text = this.renderer.width < 62 ? `${action.key} ${action.label.split(" ")[0]}` : `${action.key}  ${action.label}`
      if (x + text.length > available) break
      this.addCommand(action, x, 1, rail, false)
      x += text.length + 4
    }
  }

  private renderGhostChord(): void {
    const t = this.theme
    if (this.renderer.width < 64 || this.renderer.height < 20) {
      this.renderCompactList("CTRL+B")
      return
    }

    const big = renderBig("CTRL B")
    const size = textSize(big)
    const x = Math.max(2, Math.floor((this.renderer.width - size.width) / 2))
    const y = Math.max(3, Math.floor((this.renderer.height - size.height - 8) / 2))
    this.addText(x, y, new StyledText([rule(big, t)]), size.width, size.height)
    this.addText(x - 2, y, new StyledText([fg(FMX_FOCUS)("▎")]), 1, size.height)

    const listY = y + size.height + 2
    const totalWidth = Math.min(78, this.renderer.width - 6)
    const startX = Math.max(3, Math.floor((this.renderer.width - totalWidth) / 2))
    let cursor = startX
    for (const action of PREFIX_ACTIONS) {
      const width = action.label.length + 5
      if (cursor + width >= this.renderer.width - 2) break
      this.addCommand(action, cursor, listY)
      cursor += width
    }
    this.addText(startX, listY + 2, new StyledText([note("the stage is still present; the chord sits in front of it", t)]))
  }

  private renderCompass(): void {
    const t = this.theme
    if (this.renderer.width < 70 || this.renderer.height < 21) {
      this.renderCompactList("chord compass")
      return
    }

    const cx = Math.floor(this.renderer.width / 2)
    const cy = Math.floor(this.renderer.height / 2)
    this.addText(
      cx - 10,
      cy,
      new StyledText([rule("─────────", t), bold(primary(" CTRL+B ", t)), rule("─────────", t)]),
    )
    this.addText(cx, cy - 4, new StyledText([fg(FMX_FOCUS)("│\n│\n│")]), 1, 3)
    this.addText(cx, cy + 1, new StyledText([fg(FMX_FOCUS)("│\n│\n│")]), 1, 3)
    this.addText(cx - 1, cy, new StyledText([fg(FMX_FOCUS)("◆")]))

    this.addCommand(PREFIX_ACTIONS[0]!, cx - 6, cy - 6)
    this.addCommand(PREFIX_ACTIONS[2]!, Math.max(2, cx - 30), cy)
    this.addCommand(PREFIX_ACTIONS[3]!, Math.min(this.renderer.width - 18, cx + 18), cy)
    this.addCommand(PREFIX_ACTIONS[4]!, cx - 6, cy + 4)
    this.addCommand(PREFIX_ACTIONS[1]!, cx - 7, cy + 7)
    this.addText(cx - 21, cy + 10, new StyledText([note("previous ←      stage edge      → next", t)]))
  }

  private renderSignalSweep(): void {
    const t = this.theme
    if (this.renderer.width < 66 || this.renderer.height < 18) {
      this.renderCompactList("signal sweep")
      return
    }

    const y = Math.floor(this.renderer.height / 2)
    const left = 4
    const width = this.renderer.width - 8
    const center = Math.floor(this.renderer.width / 2)
    const reach = Math.floor((width / 2) * Math.min(6, this.pulsePhase) / 6)
    this.addText(left, y, new StyledText([rule("─".repeat(width), t)]), width, 1)
    if (reach > 0) {
      this.addText(center - reach, y, new StyledText([fg(FMX_FOCUS)("━".repeat(reach * 2 + 1))]), reach * 2 + 1, 1)
    }
    this.addText(center - 4, y - 1, new StyledText([bold(primary(" CTRL+B ", t))]))
    this.addText(center, y, new StyledText([fg(FMX_FOCUS)("●")]))

    const positions = [left + 2, left + Math.floor(width * 0.22), center - 5, left + Math.floor(width * 0.67), this.renderer.width - 18]
    PREFIX_ACTIONS.forEach((action, index) => {
      const above = index % 2 === 0
      const x = Math.max(2, Math.min(this.renderer.width - action.label.length - 7, positions[index]!))
      this.addText(x + 1, above ? y - 2 : y + 1, new StyledText([fg(FMX_FOCUS)(above ? "│" : "│")]))
      this.addCommand(action, x, above ? y - 4 : y + 3)
    })
    this.addText(Math.max(2, center - 24), y + 7, new StyledText([note("one captured pulse · five valid destinations", t)]))
  }

  private renderAperture(): void {
    const t = this.theme
    const width = Math.max(32, Math.min(70, this.renderer.width - 8))
    const height = Math.max(10, Math.min(15, this.renderer.height - 6))
    const x = Math.max(2, Math.floor((this.renderer.width - width) / 2))
    const y = Math.max(3, Math.floor((this.renderer.height - height) / 2))
    const aperture = this.addBox(x, y, width, height, {
      backgroundColor: CANVAS[t],
      border: true,
      borderColor: FMX_FOCUS,
      title: "prefix",
      titleColor: role("hint", t).fg!.hex,
    })
    const contentWidth = width - 4
    this.addText(
      2,
      2,
      new StyledText([
        paint((tokens.user_card.rail_marker as Record<Theme, StyleValue>)[t]!, "┃", t),
        bold(primary(" active agent remains legible", t)),
      ]),
      contentWidth,
      1,
      aperture,
    )
    this.addText(
      2,
      4,
      new StyledText([primary("❯ ", t), fg(FMX_FOCUS)("▎"), note("  fmx owns the next key", t)]),
      contentWidth,
      1,
      aperture,
    )

    const twoColumns = width >= 58
    PREFIX_ACTIONS.forEach((action, index) => {
      const column = twoColumns ? index % 2 : 0
      const row = twoColumns ? Math.floor(index / 2) : index
      const commandX = 3 + column * Math.floor((width - 6) / 2)
      const commandY = 7 + row * 2
      if (commandY < height - 1) this.addCommand(action, commandX, commandY, aperture)
    })
  }

  private renderKeyField(): void {
    const t = this.theme
    const columns = this.renderer.width >= 92 ? 5 : 3
    const minimumHeight = columns === 5 ? 14 : 23
    if (this.renderer.width < 58 || this.renderer.height < minimumHeight) {
      this.renderCompactList("key field")
      return
    }

    const rows = Math.ceil(PREFIX_ACTIONS.length / columns)
    const gap = 2
    const usable = Math.min(this.renderer.width - 8, columns * 18 + (columns - 1) * gap)
    const cardWidth = Math.floor((usable - (columns - 1) * gap) / columns)
    const cardHeight = 9
    const totalHeight = rows * cardHeight + (rows - 1)
    const startX = Math.max(2, Math.floor((this.renderer.width - usable) / 2))
    const startY = Math.max(3, Math.floor((this.renderer.height - totalHeight) / 2))
    const headingY = Math.max(2, startY - 2)
    this.addText(startX, headingY, solidFill(usable, 1, CANVAS[t], t), usable, 1)
    this.addText(startX, headingY, solidFill(38, 1, surface(t), t), 38, 1)
    this.addText(startX, headingY, textOnSurface("▎ the next stroke is the interface", 38, t, label), 38, 1)
    this.addText(startX, headingY, new StyledText([fg(FMX_FOCUS)("▎")]), 1, 1)
    this.addText(startX, startY, solidFill(usable, totalHeight, CANVAS[t], t), usable, totalHeight)

    PREFIX_ACTIONS.forEach((action, index) => {
      const column = index % columns
      const row = Math.floor(index / columns)
      const x = startX + column * (cardWidth + gap)
      const y = startY + row * (cardHeight + 1)
      const card = this.addBox(x, y, cardWidth, cardHeight, {
        backgroundColor: surface(t),
        onMouseDown: (event) => {
          event.stopPropagation()
          this.runAction(action)
        },
      })
      this.addText(0, 0, solidFill(cardWidth, cardHeight, surface(t), t), cardWidth, cardHeight, card)
      const glyph = renderBig(action.key.toUpperCase())
      const glyphSize = textSize(glyph)
      const glyphX = Math.max(1, Math.floor((cardWidth - glyphSize.width) / 2))
      this.addText(glyphX, 1, textOnSurface(glyph, glyphSize.width, t, secondary), glyphSize.width, glyphSize.height, card)
      const description = action.label.length >= cardWidth - 2 ? action.label.slice(0, Math.max(1, cardWidth - 3)) + "…" : action.label
      const descriptionWidth = cardWidth - 2
      const centered = description.padStart(Math.floor((descriptionWidth + description.length) / 2)).padEnd(descriptionWidth)
      this.addText(1, 7, textOnSurface(centered, descriptionWidth, t, primary), descriptionWidth, 1, card)
    })
  }

  private renderCompactList(title: string): void {
    const t = this.theme
    const width = Math.max(28, Math.min(42, this.renderer.width - 4))
    const height = Math.min(this.renderer.height - 4, PREFIX_ACTIONS.length + 5)
    const x = Math.max(1, Math.floor((this.renderer.width - width) / 2))
    const y = Math.max(2, Math.floor((this.renderer.height - height) / 2))
    const box = this.addBox(x, y, width, height, {
      backgroundColor: CANVAS[t],
      border: ["left"],
      borderColor: FMX_FOCUS,
    })
    this.addText(2, 1, new StyledText([label(title, t), note(" · ctrl+b", t)]), width - 4, 1, box)
    PREFIX_ACTIONS.forEach((action, index) => {
      if (index + 3 < height) this.addCommand(action, 2, index + 3, box)
    })
  }

  private addCommand(
    action: PrefixAction,
    x: number,
    y: number,
    parent: BoxRenderable = this.overlay,
    padded = true,
  ): TextRenderable {
    const t = this.theme
    const keyText = padded ? ` ${action.key.toUpperCase()} ` : action.key.toUpperCase()
    const chunks = [
      bg(surface(t))(bold(secondary(keyText, t))),
      bg(surface(t))(primary(` ${action.label} `, t)),
    ]
    const width = keyText.length + action.label.length + 2
    return this.addText(x, y, new StyledText(chunks), width, 1, parent, () => this.runAction(action))
  }

  private addBox(
    x: number,
    y: number,
    width: number,
    height: number,
    options: {
      backgroundColor?: ColorInput
      border?: boolean | Array<"top" | "right" | "bottom" | "left">
      borderColor?: ColorInput
      title?: string
      titleColor?: ColorInput
      onMouseDown?: (event: MouseEvent) => void
    } = {},
    parent: BoxRenderable = this.overlay,
  ): BoxRenderable {
    const box = new BoxRenderable(this.renderer, {
      position: "absolute",
      left: Math.max(0, x),
      top: Math.max(0, y),
      width: Math.max(1, width),
      height: Math.max(1, height),
      backgroundColor: options.backgroundColor ?? "#00000000",
      border: options.border ?? false,
      borderStyle: options.border ? "single" : undefined,
      borderColor: options.border ? (options.borderColor ?? role("divider", this.theme).fg!.hex) : undefined,
      title: options.title,
      titleColor: options.titleColor,
      shouldFill: options.backgroundColor !== undefined,
      onMouseDown: options.onMouseDown,
    })
    parent.add(box)
    return box
  }

  private addText(
    x: number,
    y: number,
    content: StyledText,
    width?: number,
    height?: number,
    parent: BoxRenderable = this.overlay,
    onMouseDown?: () => void,
  ): TextRenderable {
    const text = new TextRenderable(this.renderer, {
      position: "absolute",
      left: Math.max(0, x),
      top: Math.max(0, y),
      width: Math.max(1, width ?? 64),
      height: Math.max(1, height ?? 1),
      content,
      selectable: false,
      wrapMode: "none",
      truncate: true,
      onMouseDown: onMouseDown
        ? (event) => {
            event.stopPropagation()
            onMouseDown()
          }
        : undefined,
    })
    parent.add(text)
    return text
  }
}

function parseOptions(argv: string[]): PrefixModeLabOptions {
  let theme: Theme = "dark"
  let treatment = 0
  let reducedMotion = false
  for (let index = 0; index < argv.length; index++) {
    const argument = argv[index]
    if (argument === "--theme") {
      const value = argv[++index]
      if (value !== "dark" && value !== "light") throw new Error("--theme must be dark or light")
      theme = value
    } else if (argument === "--treatment") {
      const value = Number.parseInt(argv[++index] ?? "", 10)
      if (value < 1 || value > TREATMENTS.length) throw new Error(`--treatment must be 1-${TREATMENTS.length}`)
      treatment = value - 1
    } else if (argument === "--reduced-motion") {
      reducedMotion = true
    } else if (argument === "--help" || argument === "-h") {
      process.stdout.write(
        "Usage: prefix-mode-demo.sh [--theme dark|light] [--treatment 1-6] [--reduced-motion]\n\n" +
          "Inside: ctrl+b arms · 1-6 choose · left/right cycle · t theme · q quit\n",
      )
      process.exit(0)
    } else {
      throw new Error(`unknown argument: ${argument}`)
    }
  }
  return { theme, treatment, reducedMotion }
}

async function main(): Promise<void> {
  let options: PrefixModeLabOptions
  try {
    options = parseOptions(Bun.argv.slice(2))
  } catch (error) {
    process.stderr.write(`prefix-mode-demo: ${error instanceof Error ? error.message : String(error)}\n`)
    process.exit(2)
  }

  const renderer = new CliRenderer(
    process.stdin,
    process.stdout,
    process.stdout.columns || 100,
    process.stdout.rows || 30,
    { exitOnCtrlC: false, exitSignals: [] },
  )
  await renderer.setupTerminal()
  const lab = new PrefixModeLab(renderer, options)
  renderer.start()
  // A pending Promise alone does not keep every Bun/PTY combination alive.
  // Hold one quiet timer so the static scene remains interactive until the
  // lab resolves on quit.
  const keepAlive = setInterval(() => {}, 60_000)
  try {
    await lab.finished
  } finally {
    clearInterval(keepAlive)
    lab.destroy()
    renderer.destroy()
  }
}

if (import.meta.main) await main()
