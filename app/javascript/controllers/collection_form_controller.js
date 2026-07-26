import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "field"]

  show() {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
    this.fieldTarget.focus()
    this.fieldTarget.select()
  }

  hide() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
