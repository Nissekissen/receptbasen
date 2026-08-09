import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["servingsDisplay", "ingredientAmount"]
  static values = { baseServings: Number }

  connect() {
    this.currentServings = this.baseServingsValue
  }

  increment() {
    this.currentServings += 1
    this.refresh()
  }

  decrement() {
    this.currentServings = Math.max(1, this.currentServings - 1)
    this.refresh()
  }

  refresh() {
    this.servingsDisplayTarget.textContent = this.currentServings

    const ratio = this.currentServings / this.baseServingsValue

    this.ingredientAmountTargets.forEach((element) => {
      // read element.dataset.baseQuantity + element.dataset.unit,
      // scale baseQuantity by ratio, format it, and write the result
      // (plus unit, if present) back into element.textContent
      let quantity = parseFloat(element.dataset.baseQuantity);
      let unit = element.dataset.unit;
      quantity *= ratio;

      quantity = quantity.toFixed(2)
      quantity = parseFloat(quantity) // Drop trailing zeros.

      element.textContent = [ quantity, unit ].filter(Boolean).join(" ") 
    })
  }
}
