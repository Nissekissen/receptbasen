import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "content"]

  toggle() {
    const willExpand = this.contentTarget.hidden
    this.contentTarget.hidden = !willExpand
    this.triggerTarget.setAttribute("aria-expanded", willExpand)
  }
}
