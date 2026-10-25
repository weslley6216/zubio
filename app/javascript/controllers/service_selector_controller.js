import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  reload() {
    const day = this.element.querySelector("[aria-current]")?.dataset.day || new Date().toISOString().slice(0, 10)
    const serviceId = this.selectTarget.value
    document.getElementById("booking-grid").src = `/owner/appointments/new?service_id=${serviceId}&day=${day}`
    this.#retargetDayLinks(serviceId)
  }

  #retargetDayLinks(serviceId) {
    this.element.querySelectorAll("a[data-day]").forEach((link) => {
      const url = new URL(link.href)
      url.searchParams.set("service_id", serviceId)
      link.href = url.toString()
    })
  }
}
