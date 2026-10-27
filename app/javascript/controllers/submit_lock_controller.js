import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = { label: String }

  locked = false

  lock(event) {
    if (event.defaultPrevented) return

    if (this.locked) {
      event.preventDefault()
      this.buttonTargets.forEach((button) => this.#stamp(button))
      return
    }

    this.locked = true
    this.buttonTargets.forEach((button) => {
      button.dataset.submitLockOriginal = this.#label(button)
      this.#stamp(button)
    })
  }

  unlock(event) {
    if (!event.persisted) return

    this.locked = false
    this.buttonTargets.forEach((button) => {
      this.#setLabel(button, button.dataset.submitLockOriginal)
      button.disabled = false
    })
  }

  #stamp(button) {
    button.disabled = true
    this.#setLabel(button, this.labelValue)
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
