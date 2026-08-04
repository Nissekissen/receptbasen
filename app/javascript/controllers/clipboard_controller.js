import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]

  copy() {
    this.sourceTarget.select()
    navigator.clipboard.writeText(this.sourceTarget.value)

    const original = this.labelTarget.textContent
    this.labelTarget.textContent = "Kopierad!"
    setTimeout(() => { this.labelTarget.textContent = original }, 1500)
  }
}
