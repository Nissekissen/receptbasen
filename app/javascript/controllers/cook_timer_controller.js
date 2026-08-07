import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { duration: Number }

  connect() {
    this.remaining = this.durationValue
    this.running = false
  }

  disconnect() {
    this.stop()
  }

  toggle() {
    this.running ? this.pause() : this.start()
  }

  start() {
    if (this.remaining <= 0) this.remaining = this.durationValue

    this.running = true
    this.element.classList.remove("is-done")
    this.element.classList.add("is-running")
    this.timer = setInterval(() => this.tick(), 1000)
  }

  pause() {
    this.stop()
    this.element.classList.remove("is-running")
  }

  stop() {
    this.running = false
    if (this.timer) clearInterval(this.timer)
  }

  tick() {
    this.remaining -= 1
    this.render()

    if (this.remaining <= 0) {
      this.stop()
      this.element.classList.remove("is-running")
      this.element.classList.add("is-done")
    }
  }

  render() {
    const clamped = Math.max(this.remaining, 0)
    const minutes = Math.floor(clamped / 60)
    const seconds = clamped % 60
    this.displayTarget.textContent = `${minutes}:${String(seconds).padStart(2, "0")}`
  }
}
