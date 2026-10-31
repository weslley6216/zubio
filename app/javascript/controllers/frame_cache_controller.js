import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { frame: String }
  static targets = ["strip"]

  connect() {
    this.cache = new Map()
    this.inflight = new Set()
    this.queue = []
    this.onFetch = this.onFetch.bind(this)
    this.onFrameLoad = this.onFrameLoad.bind(this)
    this.onScroll = this.onScroll.bind(this)
    this.element.addEventListener("turbo:before-fetch-request", this.onFetch)
    this.element.addEventListener("turbo:frame-load", this.onFrameLoad)
    if (this.hasStripTarget) this.stripTarget.addEventListener("scroll", this.onScroll)
    this.preload()
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-fetch-request", this.onFetch)
    this.element.removeEventListener("turbo:frame-load", this.onFrameLoad)
    if (this.hasStripTarget) this.stripTarget.removeEventListener("scroll", this.onScroll)
    if (this.scrollRAF) cancelAnimationFrame(this.scrollRAF)
  }

  get frame() {
    return document.getElementById(this.frameValue)
  }

  onFetch(event) {
    const headers = event.detail.fetchOptions.headers
    if (headers["X-Sec-Purpose"] === "prefetch") return
    if (event.detail.fetchOptions.method && event.detail.fetchOptions.method.toUpperCase() !== "GET") return
    if (headers["Turbo-Frame"] !== this.frameValue) return

    const day = this.dayOf(event.detail.url)
    const entry = this.cache.has(day) ? this.cache.get(day) : this.fetchDay(day)
    event.detail.fetchRequest = { response: entry.then((response) => response.clone()) }
  }

  onFrameLoad(event) {
    if (event.target.id !== this.frameValue) return
    this.preload()
  }

  onScroll() {
    if (this.scrollRAF) return
    this.scrollRAF = requestAnimationFrame(() => {
      this.scrollRAF = null
      this.preload()
    })
  }

  dayOf(url) {
    return new URL(url, window.location.href).searchParams.get("day")
  }

  pill(day) {
    return this.element.querySelector(`a[data-day="${day}"]`)
  }

  shownDay() {
    return this.element.querySelector("a[data-day][aria-current]")?.dataset.day
  }

  fetchDay(day) {
    const pill = this.pill(day)
    const promise = fetch(pill.href, { headers: { "Turbo-Frame": this.frameValue, "Accept": "text/html, application/xhtml+xml" } })
    this.cache.set(day, promise)
    this.inflight.add(day)
    promise.then((response) => {
      this.inflight.delete(day)
      if (!response.ok || response.redirected) this.cache.delete(day)
    })
    return promise
  }

  preload() {
    if (!this.hasStripTarget) return
    const strip = this.stripTarget.getBoundingClientRect()
    const pills = Array.from(this.stripTarget.querySelectorAll("a[data-day]"))
    const visible = pills.filter((pill) => {
      const box = pill.getBoundingClientRect()
      return box.right > strip.left && box.left < strip.right
    })
    if (visible.length === 0) return

    const days = new Set(visible.map((pill) => pill.dataset.day))
    const firstIndex = pills.indexOf(visible[0])
    const lastIndex = pills.indexOf(visible[visible.length - 1])
    if (firstIndex > 0) days.add(pills[firstIndex - 1].dataset.day)
    if (lastIndex < pills.length - 1) days.add(pills[lastIndex + 1].dataset.day)

    for (const day of days) {
      if (!this.cache.has(day) && !this.inflight.has(day) && !this.queue.includes(day)) this.queue.push(day)
    }
    this.drainQueue()
  }

  drainQueue() {
    if (this.draining || this.queue.length === 0) return
    this.draining = true
    const day = this.queue.shift()
    this.fetchDay(day).finally(() => {
      this.draining = false
      this.drainQueue()
    })
  }
}
