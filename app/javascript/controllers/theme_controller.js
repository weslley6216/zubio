import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "theme"

export default class extends Controller {
  toggle() {
    const next = this.#current() === "dark" ? "light" : "dark"

    document.documentElement.dataset.theme = next
    this.#remember(next)
  }

  #current() {
    const chosen = document.documentElement.dataset.theme

    if (chosen) return chosen

    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  #remember(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch {}
  }
}
