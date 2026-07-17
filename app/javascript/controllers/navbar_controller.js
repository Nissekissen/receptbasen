import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const hero = document.querySelector(".hero")

    if (!hero) {
      this.element.classList.add("navbar--scrolled")
      return
    }

    requestAnimationFrame(() => {
      this.observer = new IntersectionObserver(
        ([entry]) => {
          this.element.classList.toggle("navbar--scrolled", !entry.isIntersecting)
        },
        { rootMargin: `-${this.element.offsetHeight}px 0px 0px 0px` }
      )

      this.observer.observe(hero)
    })
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
