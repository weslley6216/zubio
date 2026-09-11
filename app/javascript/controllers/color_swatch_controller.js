import { Controller } from "@hotwired/stimulus"

const HEX = /^#[0-9a-fA-F]{6}$/

export default class extends Controller {
  static targets = ["swatch", "text", "custom", "chip", "code", "customPanel", "readout", "panel", "linked", "own"]

  chooseOwn() {
    this.linkedTarget.checked = false
    this.ownTarget.setAttribute("aria-pressed", "true")
    this.readoutTarget.hidden = false
    this.panelTarget.hidden = false
  }

  chooseLinked() {
    this.ownTarget.setAttribute("aria-pressed", "false")
    this.readoutTarget.hidden = true
    this.panelTarget.hidden = true
  }

  openCustom() {
    this.customPanelTarget.hidden = false
    this.textTarget.focus()
  }

  syncFromSwatch() {
    this.textTarget.value = this.swatchTarget.value
    this.customTarget.checked = true
    this.showChoice()
  }

  syncFromText() {
    if (HEX.test(this.textTarget.value)) {
      this.swatchTarget.value = this.textTarget.value
    }

    this.customTarget.checked = true
    this.showChoice()
  }

  showChoice() {
    const chosen = this.element.querySelector("input[type=radio]:checked")
    if (!chosen) return

    const hex = (chosen === this.customTarget ? this.textTarget.value : chosen.value).toUpperCase()
    if (!HEX.test(hex)) return

    this.codeTarget.textContent = hex
    this.chipTarget.style.background = hex
  }
}
