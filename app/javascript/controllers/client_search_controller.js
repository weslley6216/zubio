import { Controller } from "@hotwired/stimulus"

const MIN_DIGITS = 4
const DEBOUNCE_MS = 250

export default class extends Controller {
  static targets = ["input", "results", "clientId", "nameField"]

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.#search(), DEBOUNCE_MS)
  }

  choose(event) {
    const row = event.currentTarget
    this.clientIdTarget.value = row.dataset.clientId
    this.nameFieldTarget.classList.add("hidden")
    this.resultsTarget.querySelectorAll("[aria-pressed]").forEach((button) => button.setAttribute("aria-pressed", "false"))
    row.setAttribute("aria-pressed", "true")
  }

  chooseNew() {
    this.clientIdTarget.value = ""
    this.nameFieldTarget.classList.remove("hidden")
  }

  #search() {
    const digits = this.inputTarget.value.replace(/\D/g, "")
    this.chooseNew()
    if (digits.length >= MIN_DIGITS) {
      this.resultsTarget.src = `/owner/clients?phone=${digits}`
    } else {
      this.resultsTarget.innerHTML = ""
    }
  }
}
