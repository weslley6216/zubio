import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "section", "back", "servicesList", "serviceRowTemplate", "count",
    "dayCount", "breakToggle", "break", "breakSummary",
    "serviceName", "serviceDuration", "servicePrice"
  ]
  static values = { tenant: String, open: String }

  connect() {
    this.draft = this.#readDraft()
    if (!this.#servicesPrefilled()) this.#restoreServices()
    this.#restoreFields()
    this.#syncBreak()
    this.paintInitials()
    this.index = this.#initialIndex()
    this.#render()
    this.updateDayCount()
    this.#updateServiceCount()
  }

  next() { this.#go(this.index + 1) }
  back() { this.#go(this.index - 1) }

  selectAllDays() {
    this.element.querySelectorAll('input[name="working_hours[weekdays][]"]').forEach((checkbox) => {
      checkbox.checked = true
    })
    this.updateDayCount()
    this.#save()
  }

  updateDayCount() {
    const count = this.element.querySelectorAll('input[name="working_hours[weekdays][]"]:checked').length
    this.dayCountTarget.textContent = `${count} ${count === 1 ? "dia selecionado" : "dias selecionados"}`
  }

  toggleBreak() {
    const shown = this.breakToggleTarget.checked
    this.breakTarget.classList.toggle("hidden", !shown)
    if (!shown) this.#breakFields().forEach((field) => { field.value = "" })
    this.summarizeBreak()
    this.#save()
  }

  paintInitials() {
    const initial = this.element.querySelector("#tenant_name").value.trim().charAt(0).toUpperCase()
    this.element.querySelectorAll("[data-brand-initial]").forEach((emblem) => { emblem.textContent = initial })
  }

  summarizeBreak() {
    const [ starts, ends ] = this.#breakFields()
    this.breakSummaryTarget.textContent = starts.value && ends.value ? `${starts.value} às ${ends.value}` : ""
  }

  addService() {
    const name = this.serviceNameTarget.value.trim()
    if (!name) return

    const fragment = this.serviceRowTemplateTarget.content.cloneNode(true)
    this.#fillRow(fragment.querySelector("[data-service-row]"), {
      name, duration_minutes: this.serviceDurationTarget.value, price: this.servicePriceTarget.value
    })
    this.servicesListTarget.appendChild(fragment)
    this.#clearDraft()
    this.#updateServiceCount()
    this.#save()
  }

  editService(event) {
    const row = event.target.closest("[data-service-row]")

    this.serviceNameTarget.value = this.#rowField(row, "name")
    this.serviceDurationTarget.value = this.#rowField(row, "duration_minutes")
    this.servicePriceTarget.value = this.#rowField(row, "price")
    row.remove()
    this.#updateServiceCount()
    this.#save()
  }

  removeService(event) {
    event.target.closest("[data-service-row]").remove()
    this.#updateServiceCount()
    this.#save()
  }

  save() { this.#save() }

  submit(event) {
    if (this.index !== this.sectionTargets.length - 1) {
      event.preventDefault()
      return
    }

    if (this.#logoUploading()) {
      event.preventDefault()
      const form = event.target
      this.element.addEventListener("logo:settled", () => form.requestSubmit(), { once: true })
      return
    }

    this.clear()
  }

  #logoUploading() {
    return !!this.element.querySelector("[data-upload-state='uploading']")
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
    this.backTargets.forEach((button) => { button.hidden = this.index === 0 })
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

  #breakFields() {
    return [ ...this.breakTarget.querySelectorAll("input") ]
  }

  #syncBreak() {
    const shown = this.#breakFields().some((field) => field.value)
    this.breakToggleTarget.checked = shown
    this.breakTarget.classList.toggle("hidden", !shown)
    this.summarizeBreak()
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
    return [ ...this.servicesListTarget.querySelectorAll("[data-service-row]") ].map((row) => ({
      name: this.#rowField(row, "name"),
      duration_minutes: this.#rowField(row, "duration_minutes"),
      price: this.#rowField(row, "price")
    }))
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
      const fragment = this.serviceRowTemplateTarget.content.cloneNode(true)
      this.#fillRow(fragment.querySelector("[data-service-row]"), service)
      this.servicesListTarget.appendChild(fragment)
    })
  }

  #fillRow(row, service) {
    row.querySelector("[data-service-name]").textContent = service.name
    row.querySelector("[data-service-meta]").textContent = this.#metaLabel(service)
    this.#setRowField(row, "name", service.name)
    this.#setRowField(row, "duration_minutes", service.duration_minutes)
    this.#setRowField(row, "price", service.price)
  }

  #metaLabel(service) {
    const duration = this.#durationLabel(service.duration_minutes)
    if (!duration) return ""

    return `${duration} · ${this.#priceLabel(service.price)}`
  }

  #durationLabel(minutes) {
    const value = parseInt(minutes, 10)
    if (!value) return ""

    const hours = Math.floor(value / 60)
    const rest = value % 60
    return [ hours > 0 ? `${hours} h` : null, rest > 0 ? `${rest} min` : null ].filter(Boolean).join(" ")
  }

  #priceLabel(price) {
    const text = price?.trim()
    return text ? `R$ ${text}` : "Sob consulta"
  }

  #rowField(row, attribute) {
    return row.querySelector(`[data-service-field="${attribute}"]`).value
  }

  #setRowField(row, attribute, value) {
    row.querySelector(`[data-service-field="${attribute}"]`).value = value ?? ""
  }

  #clearDraft() {
    this.serviceNameTarget.value = ""
    this.serviceDurationTarget.value = ""
    this.servicePriceTarget.value = ""
  }

  #updateServiceCount() {
    if (!this.hasCountTarget) return

    const count = this.servicesListTarget.querySelectorAll("[data-service-row]").length
    this.countTarget.textContent = count === 0 ? "Continuar" : `Continuar com ${count} ${count === 1 ? "serviço" : "serviços"}`
  }
}
