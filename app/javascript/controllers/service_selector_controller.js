import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  reload() {
    const day = this.element.querySelector("[aria-current]")?.dataset.day || new Date().toISOString().slice(0, 10)
    document.getElementById("booking-grid").src = `/owner/appointments/new?service_id=${this.selectTarget.value}&day=${day}`
  }
}
