import { Controller } from "@hotwired/stimulus"

const SUMMARY_SEPARATOR = " · "

export default class extends Controller {
  static targets = ["slot", "input", "submit", "time", "day"]
  static values = { label: { type: String, default: "Confirmar" }, includeDay: { type: Boolean, default: false }, day: String }

  connect() {
    const preselected = this.slotTargets.find((slot) => slot.getAttribute("aria-pressed") === "true")
    if (preselected) this.#choose(preselected)
  }

  select(event) { this.#choose(event.currentTarget) }

  resetDay(event) {
    this.slotTargets.forEach((slot) => slot.setAttribute("aria-pressed", "false"))
    this.inputTarget.value = ""
    this.submitTarget.disabled = true
    if (this.includeDayValue) this.dayValue = event.currentTarget.dataset.dayLabel
    this.submitTarget.textContent = this.#dayPrefix()
    if (this.hasTimeTarget) this.timeTarget.textContent = ""
    if (this.hasDayTarget) this.dayTarget.textContent = `${event.currentTarget.dataset.dayLabel}${SUMMARY_SEPARATOR}`
  }

  #choose(slot) {
    this.slotTargets.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === slot)))
    this.inputTarget.value = slot.dataset.startsAt
    this.submitTarget.disabled = false
    this.submitTarget.textContent = `${this.#dayPrefix()} ${this.includeDayValue ? "às " : ""}${slot.dataset.time}`
    if (this.hasTimeTarget) this.timeTarget.textContent = `${slot.dataset.time}${SUMMARY_SEPARATOR}`
  }

  #dayPrefix() {
    return this.includeDayValue && this.dayValue ? `${this.labelValue} ${this.dayValue}` : this.labelValue
  }
}
