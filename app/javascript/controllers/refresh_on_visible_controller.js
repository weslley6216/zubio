import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  connect() {
    this.refresh = this.refresh.bind(this)
    document.addEventListener("visibilitychange", this.refresh)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.refresh)
  }

  refresh() {
    if (document.visibilityState !== "visible") return

    Turbo.visit(window.location.href, { action: "replace" })
  }
}
