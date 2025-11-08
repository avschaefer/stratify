import { Controller } from "@hotwired/stimulus"

const DEFAULT_MESSAGE = "Are you sure you want to delete this item? This action cannot be undone."

// Connects to data-controller="confirm"
export default class extends Controller {
  static targets = ["modal", "message"]
  static values = {
    message: String,
  }

  connect() {
    this.originalForm = null
    this.isCommitting = false
    this.previouslyFocusedElement = null
  }

  disconnect() {
    this.originalForm = null
    this.isCommitting = false
    this.previouslyFocusedElement = null
  }

  handleSubmit(event) {
    if (!event?.target) return

    if (this.isCommitting) {
      this.isCommitting = false
      return
    }

    event.preventDefault()
    event.stopPropagation()

    this.originalForm = event.target
    this.updateMessage(event.submitter)
    this.openModal()
  }

  cancel(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.closeModal()
    this.originalForm = null
    this.isCommitting = false
  }

  commit(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    if (!this.originalForm) {
      console.error("confirm controller: No form associated with the confirmation action.")
      return
    }

    this.closeModal()
    this.isCommitting = true

    try {
      if (typeof this.originalForm.requestSubmit === "function") {
        this.originalForm.requestSubmit()
      } else {
        this.originalForm.submit()
      }
    } finally {
      this.originalForm = null
    }
  }

  handleDialogCancel(event) {
    event.preventDefault()
    this.cancel()
  }

  handleDialogClick(event) {
    if (!this.hasModalTarget) return

    if (event.target === this.modalTarget) {
      this.cancel(event)
    }
  }

  openModal() {
    if (!this.hasModalTarget) {
      console.error("confirm controller: Missing modal target.")
      return
    }

    const modal = this.modalTarget

    if (modal.open) return

    this.previouslyFocusedElement = document.activeElement instanceof HTMLElement
      ? document.activeElement
      : null

    if (typeof modal.showModal === "function") {
      modal.showModal()
    } else {
      modal.setAttribute("open", "open")
    }

    modal.focus()
  }

  closeModal() {
    if (!this.hasModalTarget) return

    const modal = this.modalTarget

    if (typeof modal.close === "function") {
      modal.close()
    } else {
      modal.removeAttribute("open")
    }

    if (this.previouslyFocusedElement && document.contains(this.previouslyFocusedElement)) {
      this.previouslyFocusedElement.focus()
    }

    this.previouslyFocusedElement = null
  }

  updateMessage(source) {
    if (!this.hasMessageTarget) return

    const sourceMessage = source?.dataset?.confirmMessageValue || source?.dataset?.confirmMessage
    const controllerMessage = this.messageValue || this.element?.dataset?.confirmMessageValue
    const message = sourceMessage || controllerMessage || DEFAULT_MESSAGE

    this.messageTarget.textContent = message
  }
}
