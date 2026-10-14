import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selected"]

  selectedTargetConnected(day) {
    const strip = this.element.getBoundingClientRect()
    const chosen = day.getBoundingClientRect()
    this.element.scrollLeft += chosen.left - strip.left - (strip.width - chosen.width) / 2
  }
}
