import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selected"]
  static classes = ["selected", "resting", "weekdayResting"]

  selectedTargetConnected(day) {
    const strip = this.element.getBoundingClientRect()
    const chosen = day.getBoundingClientRect()
    if (chosen.left >= strip.left && chosen.right <= strip.right) return
    this.element.scrollLeft += chosen.left - strip.left - (strip.width - chosen.width) / 2
  }

  mark(event) {
    const chosen = event.currentTarget
    this.element.querySelectorAll("[aria-current]").forEach((day) => {
      day.removeAttribute("aria-current")
      day.classList.remove(...this.selectedClasses)
      day.classList.add(...this.restingClasses)
      day.firstElementChild.classList.add(...this.weekdayRestingClasses)
    })
    chosen.setAttribute("aria-current", "date")
    chosen.classList.remove(...this.restingClasses)
    chosen.classList.add(...this.selectedClasses)
    chosen.firstElementChild.classList.remove(...this.weekdayRestingClasses)
  }
}
