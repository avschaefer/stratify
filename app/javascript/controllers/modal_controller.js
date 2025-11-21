import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog"]

  connect() {
    // Close on outside click
    this.dialogTarget.addEventListener('click', (e) => {
      if (e.target === this.dialogTarget) {
        this.close()
      }
    })
  }

  open() {
    this.dialogTarget.showModal()
    document.body.style.overflow = 'hidden' // Prevent background scroll
  }

  close(e) {
    if (e) e.preventDefault()
    this.dialogTarget.close()
    document.body.style.overflow = ''
  }
}

