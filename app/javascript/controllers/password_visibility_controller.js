import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "shown", "hidden"]

  toggle() {
    const visible = this.inputTarget.type === "text"
    this.inputTarget.type = visible ? "password" : "text"
    this.shownTarget?.toggleAttribute("hidden", visible)
    this.hiddenTarget?.toggleAttribute("hidden", !visible)
  }
}
