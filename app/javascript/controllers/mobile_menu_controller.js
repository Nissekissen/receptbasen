import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "scrim", "toggle", "closeButton"]

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.body.style.overflow = ""
  }

  open() {
    this.drawerTarget.hidden = false
    this.scrimTarget.hidden = false

    requestAnimationFrame(() => {
      this.drawerTarget.classList.add("is-open")
      this.scrimTarget.classList.add("is-open")
    })

    document.body.style.overflow = "hidden"
    this.toggleTarget.setAttribute("aria-expanded", "true")
    this.closeButtonTarget.focus()

    this.handleKeydown = (event) => { if (event.key === "Escape") this.close() }
    document.addEventListener("keydown", this.handleKeydown)
  }

  close() {
    this.drawerTarget.classList.remove("is-open")
    this.scrimTarget.classList.remove("is-open")
    document.body.style.overflow = ""
    document.removeEventListener("keydown", this.handleKeydown)
    this.toggleTarget.setAttribute("aria-expanded", "false")
    this.toggleTarget.focus()

    // transitionend covers the normal animated close; the timeout is a
    // fallback for prefers-reduced-motion, where the CSS transition is
    // disabled and transitionend would otherwise never fire. Both call the
    // same idempotent hide, so whichever fires first wins harmlessly.
    const hide = () => {
      if (!this.drawerTarget.classList.contains("is-open")) {
        this.drawerTarget.hidden = true
        this.scrimTarget.hidden = true
      }
    }
    this.drawerTarget.addEventListener("transitionend", hide, { once: true })
    setTimeout(hide, 320)
  }
}
