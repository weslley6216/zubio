import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["section", "progress", "group", "counter", "back", "servicesList", "serviceTemplate"]
  static values = { tenant: String, open: String }

  connect() {
    this.draft = this.#readDraft()
    if (!this.#servicesPrefilled()) this.#restoreServices()
    this.#restoreFields()
    this.index = this.#initialIndex()
    this.#render()
  }

  next() { this.#go(this.index + 1) }
  back() { this.#go(this.index - 1) }

  addService() {
    const fragment = this.serviceTemplateTarget.content.cloneNode(true)
    this.servicesListTarget.appendChild(fragment)
    this.#save()
  }

  removeService(event) {
    event.target.closest("[data-service-row]").remove()
    this.#save()
  }

  save() { this.#save() }

  submit(event) {
    if (this.index !== this.sectionTargets.length - 1) {
      event.preventDefault()
      return
    }

    this.clear()
  }

  clear() {
    try { localStorage.removeItem(this.#key()) } catch (error) {}
  }

  #go(target) {
    const clamped = Math.max(0, Math.min(target, this.sectionTargets.length - 1))
    const paint = () => { this.index = clamped; this.#render(); this.#save() }
    if (document.startViewTransition) document.startViewTransition(paint)
    else paint()
  }

  #render() {
    this.sectionTargets.forEach((section, position) => { section.hidden = position !== this.index })
    const current = this.sectionTargets[this.index]
    const isQuestion = current.hasAttribute("data-onboarding-question")
    this.progressTarget.hidden = !isQuestion
    this.backTargets.forEach((button) => { button.hidden = this.index === 0 })
    if (isQuestion) {
      const questions = this.sectionTargets.filter((section) => section.hasAttribute("data-onboarding-question"))
      this.groupTarget.textContent = current.dataset.onboardingGroup
      this.counterTarget.textContent = `${questions.indexOf(current) + 1} de ${questions.length}`
    }
  }

  #initialIndex() {
    if (this.openValue && this.openValue !== "welcome") return this.#indexOf(this.openValue)
    if (this.draft && this.draft.section) return this.#indexOf(this.draft.section)
    return 0
  }

  #indexOf(name) {
    return Math.max(0, this.sectionTargets.findIndex((section) => section.dataset.onboardingSection === name))
  }

  #key() {
    return `zubio:onboarding:${this.tenantValue}`
  }

  #readDraft() {
    try {
      const raw = localStorage.getItem(this.#key())
      return raw ? JSON.parse(raw) : null
    } catch (error) {
      return null
    }
  }

  #servicesPrefilled() {
    return "onboardingServicesPrefilled" in this.servicesListTarget.dataset
  }

  #save() {
    try {
      localStorage.setItem(this.#key(), JSON.stringify({
        section: this.#currentSectionName(),
        fields: this.#serializeFields(),
        services: this.#serializeServices()
      }))
    } catch (error) {}
  }

  #currentSectionName() {
    return this.sectionTargets[this.index]?.dataset.onboardingSection
  }

  #serializeFields() {
    const fields = {}
    this.element.querySelectorAll("input[name], textarea[name]").forEach((field) => {
      if (field.type === "file" || field.type === "hidden" || field.name.startsWith("services[]")) return

      if (field.type === "checkbox" && field.name.endsWith("[]")) {
        if (field.checked) fields[field.name] = [ ...(fields[field.name] || []), field.value ]
      } else if (field.type === "radio") {
        if (field.checked) fields[field.name] = field.value
      } else if (field.type !== "checkbox") {
        fields[field.name] = field.value
      }
    })
    return fields
  }

  #serializeServices() {
    return [ ...this.servicesListTarget.querySelectorAll("[data-service-row]") ].map((row) => {
      const service = {}
      row.querySelectorAll("input[name], textarea[name]").forEach((field) => {
        const attribute = field.name.match(/\[(\w+)\]$/)?.[1]
        if (attribute) service[attribute] = field.value
      })
      return service
    })
  }

  #restoreFields() {
    if (!this.draft) return

    Object.entries(this.draft.fields || {}).forEach(([ name, value ]) => this.#restoreField(name, value))
  }

  #restoreField(name, value) {
    this.element.querySelectorAll(`[name="${CSS.escape(name)}"]`).forEach((field) => {
      if (field.type === "checkbox") {
        field.checked = [].concat(value).includes(field.value)
      } else if (field.type === "radio") {
        field.checked = field.value === value
      } else {
        field.value = value
      }
      field.dispatchEvent(new Event("input", { bubbles: true }))
      field.dispatchEvent(new Event("change", { bubbles: true }))
    })
  }

  #restoreServices() {
    const services = this.draft?.services || []
    if (services.length === 0) return

    this.servicesListTarget.innerHTML = ""
    services.forEach((service) => {
      const fragment = this.serviceTemplateTarget.content.cloneNode(true)
      const row = fragment.querySelector("[data-service-row]")
      Object.entries(service).forEach(([ attribute, value ]) => {
        const field = row.querySelector(`[name$="[${attribute}]"]`)
        if (field) field.value = value
      })
      this.servicesListTarget.appendChild(fragment)
    })
  }
}
