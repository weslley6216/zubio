import { Controller } from "@hotwired/stimulus"

const HEX = /^#[0-9a-fA-F]{6}$/
const ROLE = {
  "branding[brand_600]": "previewBrand",
  "branding[brand_secondary_600]": "previewSecondary"
}

export default class extends Controller {
  static targets = ["preview"]

  choose(event) {
    const radio = event.target
    const role = ROLE[radio.name]
    if (!role) return

    if (radio.value === "") {
      this.previewTarget.dataset.previewSecondary = "none"
    } else if (HEX.test(radio.value)) {
      this.previewTarget.dataset[role] = radio.value.toUpperCase()
    }
  }

  syncFromSwatch(event) {
    const panel = event.target.closest("[data-custom]")
    panel.querySelector("[data-code]").value = event.target.value
    this.#chooseCustom(panel)
  }

  syncFromText(event) {
    const panel = event.target.closest("[data-custom]")
    if (HEX.test(event.target.value)) panel.querySelector("[data-color]").value = event.target.value
    this.#chooseCustom(panel)
  }

  #chooseCustom(panel) {
    panel.querySelector("input[type=radio]").checked = true
  }
}
