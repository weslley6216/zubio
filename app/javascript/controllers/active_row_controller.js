import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["row", "detailFrame"]
  static classes = ["active", "resting"]

  select(event) {
    this.mark(event.currentTarget.closest("[data-active-row-target='row']"))
  }

  reconcile() {
    const selected = this.detailFrameTarget.querySelector("[data-appointment-id]")?.dataset.appointmentId
    this.rowTargets.forEach((row) => this.paint(row, row.dataset.appointmentId === selected))
  }

  mark(chosen) {
    this.rowTargets.forEach((row) => this.paint(row, row === chosen))
  }

  paint(row, active) {
    row.classList.remove(...(active ? this.restingClasses : this.activeClasses))
    row.classList.add(...(active ? this.activeClasses : this.restingClasses))
    const link = row.querySelector("a[data-action~='active-row#select']")
    if (active) link.setAttribute("aria-current", "true")
    else link.removeAttribute("aria-current")
  }
}
