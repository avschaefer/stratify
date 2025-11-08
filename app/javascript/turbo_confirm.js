import { Turbo } from "@hotwired/turbo-rails"

const DIALOG_ID = "turbo-confirm-dialog"
const MESSAGE_ID = "turbo-confirm-message"
const DESCRIPTION_ID = "turbo-confirm-description"

function ensureDialog() {
  let dialog = document.getElementById(DIALOG_ID)
  if (dialog) return dialog

  dialog = document.createElement("dialog")
  dialog.id = DIALOG_ID
  dialog.classList.add("turbo-confirm-dialog")
  dialog.innerHTML = `
    <form method="dialog" class="turbo-confirm-dialog__panel">
      <div class="turbo-confirm-dialog__header">
        <h2 id="${MESSAGE_ID}"></h2>
      </div>
      <div class="turbo-confirm-dialog__body">
        <p id="${DESCRIPTION_ID}"></p>
      </div>
      <div class="turbo-confirm-dialog__footer">
        <button value="cancel" type="submit" class="btn btn-secondary">Cancel</button>
        <button value="confirm" type="submit" class="btn btn-danger">Delete</button>
      </div>
    </form>
  `

  document.body.appendChild(dialog)
  return dialog
}

function showDialog(message, description = "") {
  const dialog = ensureDialog()
  const messageEl = dialog.querySelector(`#${MESSAGE_ID}`)
  const descriptionEl = dialog.querySelector(`#${DESCRIPTION_ID}`)

  if (messageEl) messageEl.textContent = message || "Are you sure?"
  if (descriptionEl) descriptionEl.textContent = description

  if (typeof dialog.showModal === "function") {
    dialog.showModal()
  } else {
    dialog.setAttribute("open", "open")
  }

  return dialog
}

function closeDialog(dialog) {
  if (!dialog) return

  if (typeof dialog.close === "function") {
    dialog.close()
  } else {
    dialog.removeAttribute("open")
  }
}

Turbo.config.forms.confirm = (message, element) => {
  return new Promise((resolve, reject) => {
    const description =
      element?.getAttribute("data-turbo-confirm-description") ||
      element?.dataset?.turboConfirmDescription ||
      ""

    const dialog = showDialog(message, description)

    const handleClose = () => {
      const confirmed = dialog.returnValue === "confirm"
      dialog.removeEventListener("close", handleClose)
      closeDialog(dialog)

      if (confirmed) {
        resolve(true)
      } else {
        reject()
      }
    }

    dialog.addEventListener("close", handleClose, { once: true })
  })
}

