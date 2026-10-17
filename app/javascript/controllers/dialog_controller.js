import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sheet"]

  open(event) {
    event.preventDefault()
    this.sheetTarget.showModal()
  }

  close() {
    this.sheetTarget.close()
  }
}
