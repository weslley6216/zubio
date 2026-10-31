import { Controller } from "@hotwired/stimulus"

const SUMMARY_SEPARATOR = " · "

export default class extends Controller {
  static targets = ["slot", "input", "submit", "time", "day", "takenNotice"]
  static values = { label: { type: String, default: "Confirmar" }, includeDay: { type: Boolean, default: false }, day: String }

  connect() {
    const preselected = this.slotTargets.find((slot) => slot.getAttribute("aria-pressed") === "true")
    if (preselected) this.#choose(preselected)
  }

  select(event) { this.#choose(event.currentTarget) }

  resetDay(event) {
    this.#clear()
    if (this.includeDayValue) this.dayValue = event.currentTarget.dataset.dayLabel
    this.submitTarget.textContent = this.#dayPrefix()
    if (this.hasDayTarget) this.dayTarget.textContent = `${event.currentTarget.dataset.dayLabel}${SUMMARY_SEPARATOR}`
  }

  reconcile() {
    const chosen = this.inputTarget.value
    if (!chosen) return
    const slot = this.slotTargets.find((candidate) => candidate.dataset.startsAt === chosen)
    if (slot) return this.#choose(slot)
    this.#clear()
    if (this.hasTakenNoticeTarget) this.takenNoticeTarget.hidden = false
  }

  #clear() {
    this.slotTargets.forEach((slot) => slot.setAttribute("aria-pressed", "false"))
    this.inputTarget.value = ""
    this.submitTarget.disabled = true
    this.submitTarget.textContent = this.#dayPrefix()
    if (this.hasTimeTarget) this.timeTarget.textContent = ""
    this.#hideNotice()
  }

  #choose(slot) {
    this.slotTargets.forEach((candidate) => candidate.setAttribute("aria-pressed", String(candidate === slot)))
    this.inputTarget.value = slot.dataset.startsAt
    this.submitTarget.disabled = false
    this.submitTarget.textContent = `${this.#dayPrefix()} ${this.includeDayValue ? "às " : ""}${slot.dataset.time}`
    if (this.hasTimeTarget) this.timeTarget.textContent = `${slot.dataset.time}${SUMMARY_SEPARATOR}`
    this.#hideNotice()
  }

  #hideNotice() {
    if (this.hasTakenNoticeTarget) this.takenNoticeTarget.hidden = true
  }

  #dayPrefix() {
    return this.includeDayValue && this.dayValue ? `${this.labelValue} ${this.dayValue}` : this.labelValue
  }
}
