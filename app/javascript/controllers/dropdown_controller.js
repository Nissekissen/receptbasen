import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.hideBound = this.hide.bind(this)
    document.addEventListener("click", this.hideBound)
  }

  disconnect() {
    document.removeEventListener("click", this.hideBound)
  }

  toggle() {
    this.menuTarget.hidden = !this.menuTarget.hidden
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
    }
  }
}
