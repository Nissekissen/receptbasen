import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger"]

  toggle() {
    const isOpen = this.element.classList.toggle("is-open")
    this.triggerTarget.setAttribute("aria-expanded", isOpen)
  }
}
