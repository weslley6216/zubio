import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "readout"]

  count() {
    const max = this.readoutTarget.dataset.max
    const length = [...this.fieldTarget.value].length

    this.readoutTarget.textContent = `${length} de ${max} caracteres`
  }
}
