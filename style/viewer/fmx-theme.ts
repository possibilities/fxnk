import { RGBA } from "@opentui/core"

export type Theme = "dark" | "light"

// Simulated terminal backgrounds let both themes remain inspectable from any
// terminal. Fx itself inherits the terminal default instead of owning these.
export const CANVAS: Readonly<Record<Theme, string>> = { dark: "#121212", light: "#fafafa" }

// Fixed fmx carve-outs from STYLE.md. These are intentionally absent from the
// extracted Fx tokens: focus/error retain their terminal-owned ANSI slots,
// while surface/unused are the two indexed grayscale additions.
export const FMX_FOCUS = RGBA.fromIndex(4)
export const FMX_ERROR = RGBA.fromIndex(1)
export const FMX_SCRIM = "#00000033"

const SURFACE: Readonly<Record<Theme, RGBA>> = {
  dark: RGBA.fromIndex(236),
  light: RGBA.fromIndex(254),
}
const UNUSED: Readonly<Record<Theme, RGBA>> = {
  dark: RGBA.fromIndex(235),
  light: RGBA.fromIndex(255),
}

export const surface = (theme: Theme): RGBA => SURFACE[theme]
export const unused = (theme: Theme): RGBA => UNUSED[theme]
