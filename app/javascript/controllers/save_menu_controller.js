import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "checkbox", "label", "menu", "scopeList", "collectionPanel"]

  connect() {
    this.refresh();

    this.menuObserver = new MutationObserver(() => {
      if (this.menuTarget.hidden) this.showScopes()
    })
    this.menuObserver.observe(this.menuTarget, { attributes: true, attributeFilter: ["hidden"] })
  }

  disconnect() {
    this.menuObserver?.disconnect()
  }

  refresh() {
    const anyChecked = this.checkboxTargets.some((checkbox) => checkbox.checked)
    this.triggerTarget.classList.toggle("is-saved", anyChecked)

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = anyChecked ? "Sparat" : "Spara"
    }
  }

  showCollections(event) {
    const scope = event.params.scope

    this.scopeListTarget.hidden = true
    this.collectionPanelTargets.forEach((panel) => {
      panel.hidden = panel.dataset.scope !== scope
    })
  }

  showScopes() {
    this.scopeListTarget.hidden = false
    this.collectionPanelTargets.forEach((panel) => {
      panel.hidden = true
    })
  }
}
