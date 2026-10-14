import { Controller } from "@hotwired/stimulus"
import { chooseInstallInvite } from "pwa_install"

const DISMISSED_KEY = "pwa-install-dismissed"

export default class extends Controller {
  static targets = ["action", "instructions"]

  connect() {
    if (this.#dismissed()) return

    this.installEvent = null
    this.onBeforeInstallPrompt = (event) => this.#capture(event)
    this.onAppInstalled = () => this.dismiss()
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

  dismiss() {
    this.#reveal("hidden")
    this.#remember()
  }

  #capture(event) {
    event.preventDefault()
    this.installEvent = event
    this.#reveal(chooseInstallInvite(true, this.#isIOS(), this.#isStandalone(), this.#isMobile()))
  }

  #reveal(variant) {
    this.actionTarget.hidden = variant !== "action"
    this.instructionsTarget.hidden = variant !== "instructions"
    this.element.hidden = variant === "hidden"
  }

  #dismissed() {
    try {
      return localStorage.getItem(DISMISSED_KEY) === "true"
    } catch {
      return false
    }
  }

  #remember() {
    try {
      localStorage.setItem(DISMISSED_KEY, "true")
    } catch {}
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
