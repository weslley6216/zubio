import { Controller } from "@hotwired/stimulus"

const HEX = /^#[0-9a-fA-F]{6}$/

export default class extends Controller {
  static targets = ["swatch", "text", "custom", "chip", "code", "customPanel", "customToggle", "readout", "panel", "linked", "own"]

  chooseOwn() {
    this.linkedTarget.checked = false
    this.ownTarget.setAttribute("aria-expanded", "true")
    this.readoutTarget.hidden = false
    this.panelTarget.hidden = false
    this.checkReadColor()
  }

  chooseLinked() {
    this.ownTarget.setAttribute("aria-expanded", "false")
    this.readoutTarget.hidden = true
    this.panelTarget.hidden = true
  }

  toggleCustom() {
    if (this.customPanelTarget.hidden) {
      this.showCustom()
      this.textTarget.focus()
    } else {
      this.customPanelTarget.hidden = true
      this.customToggleTarget.setAttribute("aria-expanded", "false")
    }
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

  showCustom() {
    this.customPanelTarget.hidden = false
    this.customToggleTarget.setAttribute("aria-expanded", "true")
  }

  checkReadColor() {
    const hex = this.codeTarget.textContent.trim()
    const swatch = HEX.test(hex) && this.element.querySelector(`input[type=radio][value="${hex}"]`)

    if (swatch) {
      swatch.checked = true
      return
    }

    this.customTarget.checked = true
    this.showCustom()
  }
}
