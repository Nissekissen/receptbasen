import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  connect() {
    this.add()
  }

  add() {
    this.listTarget.appendChild(this.templateTarget.content.cloneNode(true))
  }

  remove(event) {
    event.target.closest(".recipe-manual--list-row").remove()
  }
}
