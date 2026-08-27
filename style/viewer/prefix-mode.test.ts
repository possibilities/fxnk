import { afterEach, describe, expect, test } from "bun:test"
import { createTestRenderer, type TestRendererSetup } from "@opentui/core/testing"
import { PrefixModeLab, TREATMENTS } from "./prefix-mode.ts"

const open: Array<{ setup: TestRendererSetup; lab: PrefixModeLab }> = []

afterEach(() => {
  for (const { setup, lab } of open.splice(0)) {
    lab.destroy()
    setup.renderer.destroy()
  }
})

async function create(width = 100, height = 30) {
  const setup = await createTestRenderer({ width, height, kittyKeyboard: true, exitOnCtrlC: false })
  const lab = new PrefixModeLab(setup.renderer, { reducedMotion: true, showIntro: false })
  open.push({ setup, lab })
  await setup.renderOnce()
  return { setup, lab }
}

async function press(setup: TestRendererSetup, key: string, modifiers: { ctrl?: boolean; shift?: boolean } = {}) {
  setup.mockInput.pressKey(key, modifiers)
  await setup.renderOnce()
}

describe("prefix mode treatments", () => {
  test("all six treatments render the real fmx action vocabulary", async () => {
    const { setup, lab } = await create()
    for (let index = 0; index < TREATMENTS.length; index++) {
      await press(setup, String(index + 1))
      await press(setup, "b", { ctrl: true })
      const frame = setup.captureCharFrame()
      const readable = frame.replaceAll("█", " ").replaceAll("\u00a0", " ")
      expect(frame).toContain(TREATMENTS[index]!.name)
      expect(readable).toContain("keybinds")
      expect(readable).toContain("detach client")
      expect(readable).toContain("prev agent")
      expect(readable).toContain("next agent")
      expect(readable).toContain("toggle tray")
      expect(lab.prefixArmed).toBe(true)
      setup.mockInput.pressEscape()
      await setup.renderOnce()
    }
  })

  test("a second stroke runs demo feedback and closes prefix mode", async () => {
    const { setup, lab } = await create()
    await press(setup, "b", { ctrl: true })
    await press(setup, "n")
    expect(lab.prefixArmed).toBe(false)
    expect(setup.captureCharFrame()).toContain("next agent · demo only")
  })

  test("an unknown second stroke says what happened", async () => {
    const { setup, lab } = await create()
    await press(setup, "b", { ctrl: true })
    await press(setup, "x")
    expect(lab.prefixArmed).toBe(false)
    expect(setup.captureCharFrame()).toContain("unbound x · prefix cancelled")
  })

  test("every treatment stays usable at narrow and shallow sizes", async () => {
    const { setup } = await create(40, 14)
    for (let index = 0; index < TREATMENTS.length; index++) {
      await press(setup, String(index + 1))
      await press(setup, "b", { ctrl: true })
      const frame = setup.captureCharFrame()
      expect(frame).toContain(TREATMENTS[index]!.name)
      expect(frame).toContain("keybinds")
      expect(frame.split("\n").length).toBeLessThanOrEqual(15)
      setup.mockInput.pressEscape()
      await setup.renderOnce()
    }
  })

  test("theme switching preserves the scene and selected treatment", async () => {
    const { setup, lab } = await create(80, 24)
    await press(setup, "5")
    await press(setup, "t")
    await press(setup, "b", { ctrl: true })
    expect(lab.activeTreatment).toBe(4)
    expect(setup.captureCharFrame()).toContain("aperture")
    expect(setup.captureCharFrame()).toContain("active agent remains legible")
  })

  test("clicking a displayed key uses the same demo action path", async () => {
    const { setup, lab } = await create()
    await press(setup, "6")
    await press(setup, "b", { ctrl: true })
    await setup.mockMouse.click(6, 12)
    await setup.renderOnce()
    expect(lab.prefixArmed).toBe(false)
    expect(setup.captureCharFrame()).toContain("keybinds · demo only")
  })
})
