import { Controller } from "@hotwired/stimulus"

const DEBOUNCE_MS = 250

export default class extends Controller {
  static targets = ["name", "field", "status"]
  static values = { url: String, maxLength: Number }

  connect() {
    this.claimed = this.fieldTarget.value.length > 0
  }

  disconnect() {
    clearTimeout(this.timer)
    this.pending?.abort()
  }

  // Assigning .value from here fires no input event, so editing the field by
  // hand is the only thing that claims it away from the establishment name.
  suggest() {
    if (this.claimed) return

    this.fieldTarget.value = this.#slugify(this.nameTarget.value)
    this.check()
  }

  // Emptying the field hands it back: the name starts driving it again.
  edit() {
    this.claimed = this.fieldTarget.value.length > 0
    this.check()
  }

  check() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.#report(), DEBOUNCE_MS)
  }

  // A rate-limited 429 has no body and an error page is not a status message,
  // so anything but a 2xx leaves the last good message on screen.
  async #report() {
    const url = `${this.urlValue}?candidate=${encodeURIComponent(this.fieldTarget.value)}`

    this.pending?.abort()
    this.pending = new AbortController()

    try {
      const response = await fetch(url, { headers: { Accept: "text/html" }, signal: this.pending.signal })
      if (!response.ok) return

      this.statusTarget.innerHTML = await response.text()
    } catch {
      // aborted or offline: the visible message stays as it was
    }
  }

  #slugify(value) {
    return value
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, this.maxLengthValue)
  }
}
