import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const PREVIEW_STEPS_AHEAD = 3

export default class extends Controller {
  static targets = [
    "step", "progressFill", "counter",
    "prevButton", "nextButton", "finishForm",
    "preview", "previewLabel", "previewList",
    "wakeLock"
  ]
  static values = { total: Number, exitUrl: String }

  connect() {
    this.index = 0
    this.update()
    this.requestWakeLock()

    this.handleVisibilityChange = this.handleVisibilityChange.bind(this)
    document.addEventListener("visibilitychange", this.handleVisibilityChange)
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.handleVisibilityChange)
    this.releaseWakeLock()
  }

  next() {
    if (this.index >= this.totalValue - 1) return
    this.index += 1
    this.update()
  }

  previous() {
    if (this.index <= 0) {
      Turbo.visit(this.exitUrlValue)
      return
    }
    this.index -= 1
    this.update()
  }

  update() {
    const isLastStep = this.index === this.totalValue - 1

    this.stepTargets.forEach((step, i) => { step.hidden = i !== this.index })
    this.progressFillTarget.style.width = `${((this.index + 1) / this.totalValue) * 100}%`
    this.counterTarget.textContent = `Steg ${this.index + 1} av ${this.totalValue}`
    this.prevButtonTarget.textContent = this.index === 0 ? "Stäng" : "Föregående"
    this.nextButtonTarget.hidden = isLastStep
    this.finishFormTarget.hidden = !isLastStep

    this.updatePreview(isLastStep)
  }

  updatePreview(isLastStep) {
    this.previewTarget.hidden = isLastStep
    if (isLastStep) return

    const upcoming = this.stepTargets.slice(this.index + 1, this.index + 1 + PREVIEW_STEPS_AHEAD)
    const [ immediate, ...rest ] = upcoming

    this.previewLabelTarget.textContent = this.stepText(immediate)
    this.previewListTarget.innerHTML = ""
    rest.forEach((step) => {
      const row = document.createElement("p")
      row.textContent = this.stepText(step)
      this.previewListTarget.appendChild(row)
    })
  }

  stepText(step) {
    return step.querySelector(".cook-mode--step-text").textContent
  }

  async requestWakeLock() {
    if (!("wakeLock" in navigator)) {
      this.wakeLockTarget.classList.add("is-unsupported")
      return
    }

    try {
      this.wakeLock = await navigator.wakeLock.request("screen")
      this.wakeLockTarget.classList.add("is-active")
      this.wakeLock.addEventListener("release", () => {
        this.wakeLockTarget.classList.remove("is-active")
      })
    } catch {
      this.wakeLockTarget.classList.add("is-unsupported")
    }
  }

  releaseWakeLock() {
    this.wakeLock?.release()
    this.wakeLock = null
  }

  // The wake lock is released automatically by the browser whenever the tab
  // is hidden, so it has to be explicitly re-requested once it's visible
  // again — otherwise the screen can lock mid-step the moment the user
  // checks another app and comes back.
  handleVisibilityChange() {
    if (document.visibilityState === "visible" && !this.wakeLock) {
      this.requestWakeLock()
    }
  }
}
