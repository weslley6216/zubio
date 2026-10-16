import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.#days().forEach((day) => this.#syncBreak(day))
    this.element.querySelectorAll("[data-copy]").forEach((button) => button.classList.remove("hidden"))
  }

  addBreak(event) {
    const day = event.target.closest("[data-day]")
    const [ starts, ends ] = this.#breakFields(day)
    if (!starts.value) starts.value = "12:00"
    if (!ends.value) ends.value = "13:00"
    this.#showBreak(day)
  }

  removeBreak(event) {
    const day = event.target.closest("[data-day]")
    this.#breakFields(day).forEach((field) => { field.value = "" })
    this.#hideBreak(day)
  }

  copyToAll(event) {
    const source = event.target.closest("[data-day]")
    const values = this.#values(source)
    this.#days().forEach((day) => {
      if (day === source || !this.#active(day)) return

      this.#apply(day, values)
      this.#syncBreak(day)
    })
  }

  #days() {
    return [ ...this.element.querySelectorAll("[data-day]") ]
  }

  #active(day) {
    return day.querySelector("input[name$='[active]']").checked
  }

  #breakBlock(day) {
    return day.querySelector("[data-break]")
  }

  #addButton(day) {
    return day.querySelector("[data-add-break]")
  }

  #breakFields(day) {
    return [ ...this.#breakBlock(day).querySelectorAll("input") ]
  }

  #field(day, key) {
    return day.querySelector(`[data-field='${key}']`)
  }

  #values(day) {
    return [ "opens_at", "closes_at", "break_starts_at", "break_ends_at" ].reduce((carry, key) => {
      carry[key] = this.#field(day, key).value
      return carry
    }, {})
  }

  #apply(day, values) {
    Object.entries(values).forEach(([ key, value ]) => { this.#field(day, key).value = value })
  }

  #syncBreak(day) {
    this.#breakFields(day).some((field) => field.value) ? this.#showBreak(day) : this.#hideBreak(day)
  }

  #showBreak(day) {
    this.#breakBlock(day).classList.remove("hidden")
    this.#addButton(day).classList.add("hidden")
  }

  #hideBreak(day) {
    this.#breakBlock(day).classList.add("hidden")
    this.#addButton(day).classList.remove("hidden")
  }
}
