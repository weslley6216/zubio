import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = [ "preview", "placeholder", "noLogo", "signedId", "state" ]
  static values = { url: String, maxBytes: Number, contentTypes: Array }

  generation = 0

  choose(event) {
    const [ file ] = event.target.files
    if (!file) return

    this.generation++

    if (!this.#accepts(file)) {
      this.#reject()
      return
    }

    this.#showPreview(file)
    if (this.hasUrlValue) this.#upload(file)
  }

  #accepts(file) {
    return this.contentTypesValue.includes(file.type) && file.size <= this.maxBytesValue
  }

  #reject() {
    this.element.querySelectorAll("input[type=file]").forEach((input) => { input.value = "" })
    this.#forget()
    this.#state("Essa imagem não foi aceita: use PNG, JPG ou WEBP com até " + this.#megabytes() + " MB.", true)
  }

  #forget() {
    if (this.hasSignedIdTarget) this.signedIdTarget.value = ""
    delete this.element.dataset.uploadState
    this.previewTarget.hidden = true
    this.placeholderTarget.hidden = false
    if (this.hasNoLogoTarget) this.noLogoTarget.hidden = false
  }

  #showPreview(file) {
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.hidden = false
    this.placeholderTarget.hidden = true
    if (this.hasNoLogoTarget) this.noLogoTarget.hidden = true
    this.#state("")
  }

  #upload(file) {
    const generation = this.generation
    this.signedIdTarget.value = ""
    this.element.dataset.uploadState = "uploading"
    this.#state("Enviando a sua logo…")

    new DirectUpload(file, this.urlValue).create((error, blob) => {
      if (generation !== this.generation) return

      if (error) {
        this.#forget()
        this.element.dataset.uploadState = "failed"
        this.#state("Não deu para enviar a logo. Toque na galeria para tentar de novo.", true)
      } else {
        this.signedIdTarget.value = blob.signed_id
        this.element.dataset.uploadState = "done"
        this.#state("Logo enviada.")
      }
      this.dispatch("settled")
    })
  }

  #state(text, error = false) {
    this.stateTarget.textContent = text
    this.stateTarget.classList.toggle("text-danger", error)
  }

  #megabytes() {
    return Math.round(this.maxBytesValue / (1024 * 1024))
  }
}
