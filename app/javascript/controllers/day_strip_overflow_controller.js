import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["scroller", "backward", "forward"]

  connect() {
    this.update = this.update.bind(this)
    this.update()
    document.addEventListener("turbo:render", this.update)
  }

  disconnect() {
    document.removeEventListener("turbo:render", this.update)
    if (this.frame) cancelAnimationFrame(this.frame)
    this.frame = null
  }

  backward() {
    this.scrollerTarget.scrollBy({ left: -this.scrollerTarget.clientWidth, behavior: "smooth" })
  }

  forward() {
    this.scrollerTarget.scrollBy({ left: this.scrollerTarget.clientWidth, behavior: "smooth" })
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
