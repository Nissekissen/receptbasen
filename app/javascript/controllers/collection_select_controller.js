import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "newName"]

  toggle() {
    this.newNameTarget.hidden = this.selectTarget.value !== "new"
  }
}
