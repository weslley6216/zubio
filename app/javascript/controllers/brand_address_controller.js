import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "address"]
  static values = { suffix: String }

  connect() {
    this.render()
  }

  render() {
    const slug = this.#slugify(this.nameTarget.value)
    this.addressTarget.textContent = slug ? `${slug}.${this.suffixValue}` : this.suffixValue
  }

  #slugify(value) {
    return value
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, this.maxLengthValue)
  }
}
