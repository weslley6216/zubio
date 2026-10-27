import { Turbo } from "@hotwired/turbo-rails"
import "controllers"

Turbo.config.drive.progressBarDelay = 800

const frameNamed = (headers) => headers && headers["Turbo-Frame"] && document.getElementById(headers["Turbo-Frame"])

document.addEventListener("turbo:before-fetch-request", (event) => {
  const headers = event.detail.fetchOptions.headers
  if (headers["X-Sec-Purpose"] === "prefetch") return

  frameNamed(headers)?.setAttribute("data-loading", "")
})

document.addEventListener("turbo:fetch-request-error", (event) => {
  frameNamed(event.detail.request.headers)?.removeAttribute("data-loading")
})

for (const name of [ "turbo:frame-render", "turbo:frame-missing" ]) {
  document.addEventListener(name, (event) => event.target.removeAttribute("data-loading"))
}
