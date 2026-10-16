import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  closeOutside(event) {
    if (this.element.open && !this.element.contains(event.target)) this.element.open = false
  }
}
