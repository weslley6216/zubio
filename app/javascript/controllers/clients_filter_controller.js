import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 250

export default class extends Controller {
  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.element.requestSubmit(), DEBOUNCE_MS)
  }
}
