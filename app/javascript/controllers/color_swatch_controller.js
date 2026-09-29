import { Controller } from "@hotwired/stimulus"

const HEX = /^#[0-9a-fA-F]{6}$/
const ROLE = {
  "branding[brand_600]": "previewBrand",
  "branding[brand_secondary_600]": "previewSecondary"
}
const PARAM = { previewBrand: "brand", previewSecondary: "secondary" }

export default class extends Controller {
  static targets = ["preview"]

  connect() {
    this.element.querySelectorAll('input[type="radio"]:checked').forEach((radio) => this.#applyRadio(radio))
  }

  choose(event) {
    this.#applyRadio(event.target)
  }

  syncFromSwatch(event) {
    const panel = event.target.closest("[data-custom]")
    panel.querySelector("[data-code]").value = event.target.value
    this.#chooseCustom(event.target)
  }

  syncFromText(event) {
    const panel = event.target.closest("[data-custom]")
    if (HEX.test(event.target.value)) panel.querySelector("[data-color]").value = event.target.value
    this.#chooseCustom(event.target)
  }

  #chooseCustom(node) {
    const fieldset = node.closest("fieldset")
    fieldset.querySelector('input[value="custom"]').checked = true
    this.#applyCustom(fieldset)
  }

  #applyRadio(radio) {
    const role = ROLE[radio.name]
    if (!role) return

    if (radio.value === "custom") this.#applyCustom(radio.closest("fieldset"))
    else if (radio.value === "") this.#paint("previewSecondary", "none")
    else if (HEX.test(radio.value)) this.#paint(role, radio.value.toUpperCase())
  }

  #applyCustom(fieldset) {
    const radio = fieldset.querySelector('input[value="custom"]')
    const role = ROLE[radio.name]
    const code = fieldset.querySelector("[data-code]")
    const message = fieldset.querySelector("[data-color-error]")

    if (HEX.test(code.value)) {
      this.#flag(code, message, false)
      const hex = code.value.toUpperCase()
      this.#ensureSheet(role, hex).then(() => this.#paint(role, hex))
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
      if (link && link.getAttribute("href") === href) { resolve(); return }
      if (!link) {
        link = document.createElement("link")
        link.id = id
        link.rel = "stylesheet"
        document.head.appendChild(link)
      }
      link.addEventListener("load", resolve, { once: true })
      link.addEventListener("error", resolve, { once: true })
      link.setAttribute("href", href)
    })
  }

  #paint(role, value) {
    if (this.hasPreviewTarget) this.previewTarget.dataset[role] = value
    const scope = this.element.closest("[data-preview-brand]")
    if (scope) scope.dataset[role] = value
  }

  #flag(code, message, invalid) {
    if (invalid) code.setAttribute("aria-invalid", "true")
    else code.removeAttribute("aria-invalid")
    if (message) message.hidden = !invalid
  }
}
