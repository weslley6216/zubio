import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scroller", "backward", "forward"]

  connect() {
    this.update = this.update.bind(this)
    this.update()
  }

  disconnect() {
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  update() {
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      this.frame = null
      const scroller = this.scrollerTarget
      this.backwardTarget.classList.toggle("hidden", scroller.scrollLeft <= 1)
      this.forwardTarget.classList.toggle("hidden", scroller.scrollLeft >= scroller.scrollWidth - scroller.clientWidth - 1)
    })
  }
}
