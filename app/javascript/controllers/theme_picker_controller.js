import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  connect() {
    this.refresh()
  }

  choose(event) {
    const value = event.currentTarget.dataset.value

    if (value === "system") {
      localStorage.removeItem("theme")
      delete document.documentElement.dataset.theme
    } else {
      localStorage.setItem("theme", value)
      document.documentElement.dataset.theme = value
    }

    this.refresh()
  }

  refresh() {
    const current = localStorage.getItem("theme") || "system"
    this.optionTargets.forEach((option) => {
      option.classList.toggle("is-active", option.dataset.value === current)
    })
  }
}
