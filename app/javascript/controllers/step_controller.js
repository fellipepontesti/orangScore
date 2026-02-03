import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step"]

  connect () {
    this.index = 0
    this.show()
  }

  next () {
    if (this.index < this.stepTargets.length - 1) {
      this.index++
      this.show()
    }
  }

  prev () {
    if (this.index > 0) {
      this.index--
      this.show()
    }
  }

  show () {
    this.stepTargets.forEach((el, i) => {
      el.classList.toggle("hidden", i !== this.index)
    })
  }
}
