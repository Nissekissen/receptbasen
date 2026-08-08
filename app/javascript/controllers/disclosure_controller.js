import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger"]

  connect() {
    this.hideBound = this.hide.bind(this)
    document.addEventListener("click", this.hideBound)
  }

  disconnect() {
    document.removeEventListener("click", this.hideBound)
  }

  toggle() {
    this.setOpen(!this.element.classList.contains("is-open"))
  }

  hide(event) {
    if (!this.element.contains(event.target)) this.setOpen(false)
  }

  setOpen(isOpen) {
    this.element.classList.toggle("is-open", isOpen)
    this.triggerTarget.setAttribute("aria-expanded", isOpen)
  }
}
