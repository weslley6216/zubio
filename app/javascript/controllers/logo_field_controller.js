import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["hint"]

  showChosen(event) {
    const [ file ] = event.target.files

    if (file) this.hintTarget.textContent = file.name
  }
}
