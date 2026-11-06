import { Controller } from "@hotwired/stimulus"

const HEX = /^#[0-9a-fA-F]{6}$/
const ROLE = {
  "branding[brand_background]": "previewBg",
  "branding[brand_600]": "previewAccent"
}
const PARAM = { previewBg: "bg", previewAccent: "accent" }
const BACKGROUND = "branding[brand_background]"
const ACCENT = "branding[brand_600]"
const BACKGROUND_CODE = "branding[brand_background_custom]"
const TONES_PATH = "/owner/brand_color_tones"
const ACCENT_PATH = "/owner/brand_accent_swatches"
const HUE_DELAY = 150

export default class extends Controller {
  static targets = ["preview"]

  connect() {
    this.element.querySelectorAll('input[type="radio"]:checked').forEach((radio) => this.#applyRadio(radio))
  }

  disconnect() {
    clearTimeout(this.hueTimer)
  }

  choose(event) {
    const radio = event.target
    if (radio.dataset.tone) { this.#takeTone(radio); return }

    this.#applyRadio(radio)
    if (radio.name === BACKGROUND && radio.checked && radio.value !== "custom") this.#refreshAccent()
  }

  dragHue(event) {
    const fieldset = event.target.closest("fieldset")
    const hue = event.target.value
    clearTimeout(this.hueTimer)
    this.hueTimer = setTimeout(() => this.#loadTones(fieldset, { hue }), HUE_DELAY)
  }

  chooseNeutral(event) {
    this.#loadTones(event.target.closest("fieldset"), { hue: "neutral" })
  }

  syncFromText(event) {
    this.#syncCustom(event)
    const code = event.target
    if (event.detail?.restored || !HEX.test(code.value)) return

    this.#loadTones(code.closest("fieldset"), { hex: code.value.toUpperCase() })
    if (code.name === BACKGROUND_CODE) this.#refreshAccent()
  }

  arrive(event) {
    const frame = event.target
    if (frame.id.startsWith("tones-")) this.#arriveTones(frame)
    else this.#arriveAccent(frame)
  }

  #arriveTones(frame) {
    const hue = frame.querySelector("[data-tone-row]")?.dataset.toneHue
    if (hue && hue !== "neutral") frame.closest("fieldset").querySelector("input[data-hue]").value = hue

    const tone = frame.querySelector("[data-tone]:checked")
    if (tone) this.#takeTone(tone)
  }

  #arriveAccent(frame) {
    const radio = frame.querySelector('input[type="radio"]:checked')
    if (radio) this.#applyRadio(radio)
  }

  #takeTone(tone) {
    const fieldset = tone.closest("fieldset")
    const custom = fieldset.querySelector('input[value="custom"]')
    fieldset.querySelector("[data-code]").value = tone.value
    custom.checked = true
    this.#applyCustom(fieldset)
    if (custom.name === BACKGROUND) this.#refreshAccent()
  }

  #loadTones(fieldset, query) {
    const frame = fieldset.querySelector('turbo-frame[id^="tones-"]')
    const params = new URLSearchParams({ role: frame.id.replace("tones-", ""), ...query })
    const background = this.#currentBackground()
    if (background) params.set("bg", background)
    frame.src = `${TONES_PATH}?${params}`
  }

  #refreshAccent() {
    queueMicrotask(() => {
      const background = this.#currentBackground()
      if (!background) return

      const accentCustom = this.element.querySelector(`input[name="${ACCENT}"][value="custom"]`)
      if (accentCustom?.checked) {
        const code = accentCustom.closest("fieldset").querySelector("[data-code]")
        if (HEX.test(code.value)) this.#loadTones(accentCustom.closest("fieldset"), { hex: code.value.toUpperCase() })
      }

      const frame = this.element.querySelector("turbo-frame#accent-swatches")
      if (!frame) return
      const params = new URLSearchParams({ bg: background })
      const chosen = frame.querySelector('input[type="radio"]:checked')
      if (chosen) params.set("selected", chosen.dataset.accent)
      frame.src = `${ACCENT_PATH}?${params}`
    })
  }

  #currentBackground() {
    const radio = this.element.querySelector(`input[name="${BACKGROUND}"]:checked`)
    if (!radio) return null
    if (radio.value !== "custom") return radio.value.toUpperCase()

    const code = radio.closest("fieldset").querySelector("[data-code]").value
    return HEX.test(code) ? code.toUpperCase() : null
  }

  #syncCustom(event) {
    const fieldset = event.target.closest("fieldset")
    const custom = fieldset.querySelector('input[value="custom"]')
    if (!event.detail?.restored) custom.checked = true
    if (custom.checked) this.#applyCustom(fieldset)
  }

  #applyRadio(radio) {
    const role = ROLE[radio.name]
    if (!role || !radio.checked) return

    if (radio.value === "custom") this.#applyCustom(radio.closest("fieldset"))
    else if (HEX.test(radio.value)) this.#applyHex(role, radio.value.toUpperCase(), radio)
  }

  #applyHex(role, hex, radio) {
    const reajusted = radio.dataset.accent && radio.dataset.accent.toUpperCase() !== hex
    if (!reajusted) { this.#paint(role, hex); return }

    this.#ensureSheet(role, hex).then((loaded) => {
      if (loaded && radio.checked) this.#paint(role, hex)
    })
  }

  #applyCustom(fieldset) {
    const radio = fieldset.querySelector('input[value="custom"]')
    const role = ROLE[radio.name]
    const code = fieldset.querySelector("[data-code]")
    const message = fieldset.querySelector("[data-color-error]")

    if (HEX.test(code.value)) {
      this.#flag(code, message, false)
      const hex = code.value.toUpperCase()
      this.#ensureSheet(role, hex).then((loaded) => {
        if (loaded && radio.checked && code.value.toUpperCase() === hex) this.#paint(role, hex)
      })
    } else {
      this.#flag(code, message, true)
    }
  }

  #ensureSheet(role, hex) {
    const param = PARAM[role]
    const id = `preview-sheet-${param}`
    const href = `/preview.css?${param}=${encodeURIComponent(hex)}`
    return new Promise((resolve) => {
      let link = document.getElementById(id)
      if (link && link.getAttribute("href") === href && link.dataset.state) { resolve(link.dataset.state === "loaded"); return }
      if (!link) {
        link = document.createElement("link")
        link.id = id
        link.rel = "stylesheet"
        document.head.appendChild(link)
      }
      link.addEventListener("load", () => { link.dataset.state = "loaded"; resolve(true) }, { once: true })
      link.addEventListener("error", () => { link.remove(); resolve(false) }, { once: true })
      if (link.getAttribute("href") !== href) {
        delete link.dataset.state
        link.setAttribute("href", href)
      }
    })
  }

  #paint(role, value) {
    if (this.hasPreviewTarget) this.previewTarget.dataset[role] = value
    const scope = this.element.closest("[data-preview-bg]")
    if (scope) scope.dataset[role] = value
  }

  #flag(code, message, invalid) {
    if (invalid) {
      code.setAttribute("aria-invalid", "true")
      code.setAttribute("aria-describedby", message.id)
    } else {
      code.removeAttribute("aria-invalid")
      code.removeAttribute("aria-describedby")
    }
    message.hidden = !invalid
  }
}
