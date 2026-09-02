import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["stage", "option"]

  pick({ params: { key } }) {
    this.stageTarget.dataset.demoBrand = key
    this.optionTargets.forEach((option) => {
      option.setAttribute("aria-pressed", String(option.dataset.showcaseBrandKeyParam === key))
    })
  }
}
