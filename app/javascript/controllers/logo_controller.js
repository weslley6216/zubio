import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = [ "preview", "placeholder", "noLogo", "signedId", "state" ]
  static values = { url: String, maxBytes: Number, contentTypes: Array }

  choose(event) {
    const [ file ] = event.target.files
    if (!file) return

    if (!this.#accepts(file)) {
      this.#reject(event.target)
      return
    }

    this.#showPreview(file)
    if (this.hasUrlValue) this.#upload(file)
  }

  #accepts(file) {
    return this.contentTypesValue.includes(file.type) && file.size <= this.maxBytesValue
  }

  #reject(input) {
    input.value = ""
    this.previewTarget.hidden = true
    this.placeholderTarget.hidden = false
    this.#state("Essa imagem não foi aceita: use PNG, JPG ou WEBP com até " + this.#megabytes() + " MB.", true)
  }

  #showPreview(file) {
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.hidden = false
    this.placeholderTarget.hidden = true
    if (this.hasNoLogoTarget) this.noLogoTarget.hidden = true
    this.#state("")
  }

  #upload(file) {
    this.element.dataset.uploadState = "uploading"
    this.#state("Enviando a sua logo…")

    new DirectUpload(file, this.urlValue).create((error, blob) => {
      if (error) {
        this.signedIdTarget.value = ""
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
