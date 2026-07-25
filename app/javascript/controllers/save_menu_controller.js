import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "checkbox", "label"]

  connect() {
    this.refresh();
  }

  refresh() {
    const anyChecked = this.checkboxTargets.some((checkbox) => checkbox.checked)
    this.triggerTarget.classList.toggle("is-saved", anyChecked)

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = anyChecked ? "Sparat" : "Spara"
    }
  }
}
