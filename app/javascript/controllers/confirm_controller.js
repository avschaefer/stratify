import { Controller } from "@hotwired/stimulus"

const DEFAULT_MESSAGE = "Are you sure you want to delete this item? This action cannot be undone."

// Connects to data-controller="confirm"
export default class extends Controller {
  static targets = ["modal", "message"]
  static values = {
    message: String,
  }

  connect() {
    this.resetState()
  }

  disconnect() {
    this.resetState()
  }

  handleSubmit(event) {
    if (!event?.target) return

    if (this.isCommitting) {
      this.isCommitting = false
      return
    }

    event.preventDefault()
    event.stopPropagation()

    this.beginConfirmation(event.target, event.submitter)
  }

  handleButtonClick(event) {
    if (!event?.currentTarget) return

    if (this.isCommitting) {
      event.preventDefault()
      return
    }

    const form = event.currentTarget.closest("form")
    if (!form) return

    event.preventDefault()
    event.stopPropagation()

    this.beginConfirmation(form, event.currentTarget)
  }

  cancel(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }

    this.closeModal()
    this.resetState()
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

    const form = this.originalForm
    const submitter = this.originalSubmitter
    const turboConfirmValue = form?.dataset?.turboConfirm ?? null

    this.closeModal()
    this.isCommitting = true

    try {
      this.disableTurboConfirm(form)
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit(submitter || undefined)
      } else {
        form.submit()
      }
    } finally {
      this.restoreTurboConfirm(form, turboConfirmValue)
      this.resetState()
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

  disableTurboConfirm(form) {
    if (!form) return

    if (form.hasAttribute("data-turbo-confirm")) {
      form.setAttribute("data-confirm-original-turbo-confirm", form.dataset.turboConfirm || "")
      form.removeAttribute("data-turbo-confirm")
    }
  }

  restoreTurboConfirm(form, value) {
    if (!form) return

    if (value) {
      form.setAttribute("data-turbo-confirm", value)
    } else {
      form.removeAttribute("data-turbo-confirm")
    }

    form.removeAttribute("data-confirm-original-turbo-confirm")
  }

  beginConfirmation(form, submitter = null) {
    if (!form) {
      console.error("confirm controller: Missing form for confirmation.")
      return
    }

    this.originalForm = form
    this.originalSubmitter = submitter
    this.updateMessage(submitter)
    this.openModal()
  }

  resetState() {
    this.originalForm = null
    this.originalSubmitter = null
    this.isCommitting = false
    this.previouslyFocusedElement = null
  }
}
