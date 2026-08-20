import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: Number }

  submit() {
    if (this.delayValue > 0) {
      clearTimeout(this.timeout)
      this.timeout = setTimeout(() => this.element.requestSubmit(), this.delayValue)
    } else {
      this.element.requestSubmit()
    }
  }
}
