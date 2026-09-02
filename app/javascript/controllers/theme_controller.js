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

  // Private browsing and blocked site data make localStorage throw on write;
  // the theme still applies for this page view.
  #remember(theme) {
    try {
      localStorage.setItem(STORAGE_KEY, theme)
    } catch {
      // no-op
    }
  }
}
