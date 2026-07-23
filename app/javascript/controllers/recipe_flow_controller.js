import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["viewport", "track", "panel", "dot"]

  trackTargetConnected() {
    this.setHeight(0)
    this.setActiveDot(1)
  }

  advance() {
    this.goTo(1)
  }

  save() {
  }

  goTo(index) {
    this.trackTarget.style.transform = `translateX(-${index * 100}%)`
    this.setHeight(index)
    this.setActiveDot(index + 1)
  }

  setHeight(index) {
    const panel = this.panelTargets[index]
    if (panel) this.viewportTarget.style.height = `${panel.scrollHeight}px`
  }

  setActiveDot(activeIndex) {
    this.dotTargets.forEach((dot, i) => {
      dot.classList.toggle("is-active", i === activeIndex)
      dot.classList.toggle("is-done", i < activeIndex)
    })
  }
}
