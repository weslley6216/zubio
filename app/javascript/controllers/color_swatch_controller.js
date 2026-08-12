import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["swatch", "text"]

  syncFromSwatch() {
    this.textTarget.value = this.swatchTarget.value
  }

  syncFromText() {
    if (/^#[0-9a-fA-F]{6}$/.test(this.textTarget.value)) {
      this.swatchTarget.value = this.textTarget.value
    }
  }
}
