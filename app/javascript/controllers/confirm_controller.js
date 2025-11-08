import { Controller } from "@hotwired/stimulus"

const DEFAULT_MESSAGE = "Are you sure you want to delete this item? This action cannot be undone."

// Connects to data-controller="confirm"
export default class extends Controller {
  static targets = ["modal", "message"]
  static values = {
    message: String
  }

  connect() {
    this.originalForm = null
    this.isCommitting = false
    this.boundHandleFormSubmit = this.handleFormSubmit.bind(this)
    this.boundHandleButtonClick = this.handleButtonClick.bind(this)

    // Listen for form submissions from hidden button_to forms (capture phase for early interception)
    document.addEventListener("submit", this.boundHandleFormSubmit, true)
    
    // Listen for clicks on all buttons within our controller scope to catch delete buttons
    const buttons = this.element.querySelectorAll("button")
    buttons.forEach(button => {
      // Only listen to buttons that appear to be delete buttons
      if (this.isDeleteButton(button)) {
        button.addEventListener("click", this.boundHandleButtonClick)
      }
    })
  }

  isDeleteButton(button) {
    // Check if button has delete-related attributes
    const ariaLabel = button.getAttribute("aria-label") || ""
    const title = button.getAttribute("title") || ""
    const classList = button.className || ""
    
    return (
      ariaLabel.toLowerCase().includes("delete") ||
      title.toLowerCase().includes("delete") ||
      classList.includes("btn-outline-danger") ||
      classList.includes("btn-danger")
    )
  }

  disconnect() {
    document.removeEventListener("submit", this.boundHandleFormSubmit, true)
    
    // Remove all button click listeners within our scope
    const buttons = this.element.querySelectorAll("button")
    buttons.forEach(button => {
      if (this.isDeleteButton(button)) {
        button.removeEventListener("click", this.boundHandleButtonClick)
      }
    })
    
    this.originalForm = null
    this.boundHandleFormSubmit = null
    this.boundHandleButtonClick = null
    this.isCommitting = false
  }

  handleFormSubmit(event) {
    // Only intercept if this form is related to our controller element
    if (!event.target) return
    
    // Check if the form is associated with our delete button
    const isOurForm = this.element.contains(event.target) || 
                     this.element.querySelector(`button[form="${event.target.id}"]`)
    
    if (!isOurForm) return
    
    if (this.isCommitting) {
      this.isCommitting = false
      return
    }

    event.preventDefault()
    event.stopPropagation()

    this.originalForm = event.target
    this.updateMessage(event.target)
    this.openModal()
  }

  handleButtonClick(event) {
    // Intercept delete button clicks to show confirmation modal
    const button = event.currentTarget
    const form = button.closest("form") || button.form

    if (!form) {
      console.warn("confirm controller: Could not find form for delete button, will use default behavior")
      return
    }

    // Prevent the form from submitting immediately
    event.preventDefault()
    event.stopPropagation()

    this.originalForm = form
    this.updateMessage(button)
    this.openModal()
  }

  showModal(event) {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const form = button.closest("form") || button.form

    if (!form) {
      console.error("confirm controller: Could not find form for delete action.")
      return
    }

    this.originalForm = form
    this.updateMessage(button)
    this.openModal()
  }

  cancel() {
    this.closeModal()
    this.originalForm = null
    this.isCommitting = false
  }

  commit() {
    this.closeModal()

    this.isCommitting = true

    if (this.originalForm) {
      this.originalForm.requestSubmit()
      this.originalForm = null
    } else {
      console.error("confirm controller: No form to submit.")
      this.isCommitting = false
    }
  }

  openModal() {
    if (!this.hasModalTarget) {
      console.error("confirm controller: Missing modal target.")
      return
    }

    const modal = this.modalTarget

    if (typeof modal.showModal === "function") {
      modal.showModal()
    } else {
      modal.setAttribute("open", "open")
    }
  }

  closeModal() {
    if (!this.hasModalTarget) return

    const modal = this.modalTarget

    if (typeof modal.close === "function") {
      modal.close()
    } else {
      modal.removeAttribute("open")
    }
  }

  updateMessage(source) {
    if (!this.hasMessageTarget) return

    const sourceMessage = source?.dataset?.confirmMessageValue
    const controllerMessage = this.messageValue || this.element?.dataset?.confirmMessageValue

    this.messageTarget.textContent = controllerMessage || sourceMessage || DEFAULT_MESSAGE
  }
}

