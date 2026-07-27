import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.originalHTML = this.buttonTarget.innerHTML
    this.element.addEventListener("turbo:submit-start", this.start.bind(this))
    this.element.addEventListener("turbo:submit-end", this.end.bind(this))
  }

  start() {
    this.buttonTarget.disabled = true
    this.buttonTarget.innerHTML = `<span class="btn--spinner"></span>${this.originalHTML}`
  }

  end() {
    this.buttonTarget.disabled = false
    this.buttonTarget.innerHTML = this.originalHTML
  }
}
