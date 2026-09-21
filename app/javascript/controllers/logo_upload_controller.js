import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

export default class extends Controller {
  static targets = ["signedId"]
  static values = { url: String }

  upload(event) {
    const [file] = event.target.files
    if (!file) return

    const direct = new DirectUpload(file, this.urlValue)
    direct.create((error, blob) => {
      if (!error) this.signedIdTarget.value = blob.signed_id
    })
  }
}
