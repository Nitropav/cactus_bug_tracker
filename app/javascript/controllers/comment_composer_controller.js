import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "count"]

  connect() {
    this.updateCount()
  }

  insertTemplate(event) {
    const template = event.params.template || ""
    if (!this.hasInputTarget) return

    const current = this.inputTarget.value
    this.inputTarget.value = current ? `${current}\n\n${template}` : template
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.focus()
    this.moveCursorToEnd()
  }

  clear() {
    if (!this.hasInputTarget) return

    this.inputTarget.value = ""
    this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
    this.inputTarget.focus()
  }

  updateCount() {
    if (!(this.hasInputTarget && this.hasCountTarget)) return

    const count = this.inputTarget.value.length
    this.countTarget.textContent = `${count} chars`
  }

  moveCursorToEnd() {
    const length = this.inputTarget.value.length
    this.inputTarget.setSelectionRange(length, length)
  }
}
