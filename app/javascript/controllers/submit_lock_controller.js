import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { label: String }

  lock(event) {
    if (event.defaultPrevented) return

    this.buttonTargets.forEach((button) => {
      button.dataset.submitLockOriginal = this.#label(button)
      button.disabled = true
      this.#setLabel(button, this.labelValue)
    })
  }

  unlock(event) {
    if (!event.persisted) return

    this.buttonTargets.forEach((button) => {
      this.#setLabel(button, button.dataset.submitLockOriginal)
      button.disabled = false
    })
  }

  #label(button) {
    return button.tagName === "INPUT" ? button.value : button.textContent
  }

  #setLabel(button, text) {
    if (button.tagName === "INPUT") {
      button.value = text
    } else {
      button.textContent = text
    }
  }
}
