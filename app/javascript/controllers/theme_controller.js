import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cactus-theme"

export default class extends Controller {
  static targets = ["label"]

  connect() {
    this.apply(this.currentTheme())
  }

  toggle() {
    const nextTheme = this.currentTheme() === "dark" ? "light" : "dark"
    this.apply(nextTheme)
  }

  currentTheme() {
    return document.documentElement.dataset.theme || "light"
  }

  apply(theme) {
    document.documentElement.dataset.theme = theme

    try {
      window.localStorage.setItem(STORAGE_KEY, theme)
    } catch (error) {
      // Ignore storage failures and keep the active theme in memory only.
    }

    if (this.hasLabelTarget) {
      this.labelTarget.textContent = theme === "dark" ? "Dark mode" : "Light mode"
    }
  }
}
