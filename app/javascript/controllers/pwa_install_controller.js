import { Controller } from "@hotwired/stimulus"
import { chooseInstallInvite } from "pwa_install"

export default class extends Controller {
  static targets = ["action", "instructions"]
  static values = {
    audience: String,
    snoozeDays: { type: Number, default: 0 },
    requireVisit: Boolean,
    markVisit: Boolean,
    standalonePath: String
  }

  connect() {
    if (this.standalonePathValue && this.#isStandalone()) this.#recordInstallation()
    if (this.markVisitValue) this.#markVisit()
    if (this.#dismissed()) return
    if (this.requireVisitValue && !this.#visited()) return

    this.installEvent = null
    this.onBeforeInstallPrompt = (event) => this.#capture(event)
    this.onAppInstalled = () => this.#onAppInstalled()
    window.addEventListener("beforeinstallprompt", this.onBeforeInstallPrompt)
    window.addEventListener("appinstalled", this.onAppInstalled)
    this.#reveal(chooseInstallInvite(false, this.#isIOS(), this.#isStandalone(), this.#isMobile()))
  }

  disconnect() {
    window.removeEventListener("beforeinstallprompt", this.onBeforeInstallPrompt)
    window.removeEventListener("appinstalled", this.onAppInstalled)
  }

  install() {
    this.installEvent?.prompt()
  }

  dismiss(event) {
    this.#reveal("hidden")
    if (event.params.forever || this.snoozeDaysValue === 0) {
      this.#rememberForever()
    } else {
      this.#snooze()
    }
  }

  #capture(event) {
    event.preventDefault()
    this.installEvent = event
    this.#reveal(chooseInstallInvite(true, this.#isIOS(), this.#isStandalone(), this.#isMobile()))
  }

  #onAppInstalled() {
    this.#reveal("hidden")
    this.#rememberForever()
  }

  #reveal(variant) {
    this.actionTarget.hidden = variant !== "action"
    this.instructionsTarget.hidden = variant !== "instructions"
    this.element.hidden = variant === "hidden"
  }

  #dismissed() {
    try {
      if (localStorage.getItem(this.#dismissedKey) === "true") return true
      const snoozeUntil = Number(localStorage.getItem(this.#snoozeKey))
      return Boolean(snoozeUntil) && Date.now() < snoozeUntil
    } catch {
      return false
    }
  }

  #visited() {
    try {
      return localStorage.getItem(this.#visitedKey) === "true"
    } catch {
      return false
    }
  }

  #markVisit() {
    try {
      localStorage.setItem(this.#visitedKey, "true")
    } catch {}
  }

  #rememberForever() {
    try {
      localStorage.setItem(this.#dismissedKey, "true")
    } catch {}
  }

  #snooze() {
    try {
      localStorage.setItem(this.#snoozeKey, String(Date.now() + this.snoozeDaysValue * 86400000))
    } catch {}
  }

  async #recordInstallation() {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      await fetch(this.standalonePathValue, {
        method: "POST",
        headers: { "X-CSRF-Token": csrfToken, "Accept": "application/json" }
      })
    } catch {}
  }

  get #dismissedKey() {
    return `pwa-install-dismissed:${this.audienceValue}`
  }

  get #snoozeKey() {
    return `pwa-install-snooze:${this.audienceValue}`
  }

  get #visitedKey() {
    return `pwa-install-visited:${this.audienceValue}`
  }

  #isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) || (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1)
  }

  #isStandalone() {
    return window.matchMedia("(display-mode: standalone)").matches || navigator.standalone === true
  }

  #isMobile() {
    return navigator.userAgentData ? navigator.userAgentData.mobile : window.matchMedia("(pointer: coarse)").matches
  }
}
