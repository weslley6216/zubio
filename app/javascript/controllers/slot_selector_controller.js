import { Controller } from "@hotwired/stimulus"

const CONFIRM_LABEL = "Confirmar"

export default class extends Controller {
  static targets = ["slot", "input", "submit", "time"]

  connect() {
    const preselected = this.slotTargets.find((slot) => slot.getAttribute("aria-pressed") === "true")
    if (preselected) this.#choose(preselected)
  }

  select(event) {
    this.#choose(event.currentTarget)
  }

  #choose(slot) {
    this.slotTargets.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === slot)))
    this.inputTarget.value = slot.dataset.startsAt
    this.submitTarget.disabled = false
    this.submitTarget.textContent = `${CONFIRM_LABEL} ${slot.dataset.time}`
    if (this.hasTimeTarget) this.timeTarget.textContent = `${slot.dataset.time} · `
  }
}
