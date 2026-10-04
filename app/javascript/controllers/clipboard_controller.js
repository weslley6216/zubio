import { Controller } from "@hotwired/stimulus"

const RESET_DELAY = 2000

export default class extends Controller {
  static targets = ["label"]
  static values = { text: String, copied: String }

  copy() {
    navigator.clipboard?.writeText(this.textValue)?.then(() => this.#confirm()).catch(() => {})
  }

  #confirm() {
    if (this.resetTimer) clearTimeout(this.resetTimer)
    this.defaultLabel ??= this.labelTarget.textContent
    this.labelTarget.textContent = this.copiedValue
    this.resetTimer = setTimeout(() => { this.labelTarget.textContent = this.defaultLabel }, RESET_DELAY)
  }
}
