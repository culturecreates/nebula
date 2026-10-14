import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static values = { uri: String }

  connect() {
    // Move the prompt modal to <body> so no ancestor's stacking context can put the backdrop over it.
    // On a Turbo cache restore the modal may already live in <body> (not inside this element): reuse it then.
    const promptEl = this.element.querySelector("#mergeModal") || document.querySelector("body > #mergeModal")
    if (!promptEl) return
    document.querySelectorAll("body > #mergeModal").forEach(el => { if (el !== promptEl) el.remove() }) // stale copies
    if (promptEl.parentElement !== document.body) document.body.appendChild(promptEl)
    this.promptEl = promptEl
    // Moved outside this controller's element, so Stimulus actions/targets no longer reach it: wire it up by hand.
    this.input = promptEl.querySelector("input")
    this.onPreview = event => this.preview(event)
    this.onEnter = event => { if (event.key === "Enter") this.preview(event) }
    promptEl.querySelector("[data-role='preview']").addEventListener("click", this.onPreview)
    this.input.addEventListener("keydown", this.onEnter)
    this.promptModal = bootstrap.Modal.getOrCreateInstance(promptEl)
    // Shared with refresh_entity_controller: reuse the one instance Bootstrap registers for the
    // element, or the close/X buttons act on a different instance than the one that was shown.
    this.modal = bootstrap.Modal.getOrCreateInstance(document.getElementById("dryrunModal"))
    this.modalLabel = document.getElementById("dryrunModalLabel")
    this.modalBody = document.getElementById("dryrunModalBody")
    this.okBtn = document.getElementById("dryrunModalOk")
  }

  disconnect() {
    this.promptEl?.querySelector("[data-role='preview']")?.removeEventListener("click", this.onPreview)
    this.input?.removeEventListener("keydown", this.onEnter)
    this.promptModal?.dispose()
    this.promptEl?.remove()
  }

  open(event) {
    event.preventDefault()
    this.promptModal.show()
    this.input.focus()
  }

  preview(event) {
    event.preventDefault()
    const otherUri = this.input.value.trim()
    if (!otherUri) return

    this.modalLabel.textContent = "Merge Preview"
    this.modalBody.innerHTML = "<div class='text-center'><span class='spinner-border spinner-border-sm' role='status' aria-hidden='true'></span> Calculating...</div>"
    this.okBtn.disabled = true
    // Show the preview only once the prompt has finished hiding; overlapping two modals'
    // transitions leaves Bootstrap's backdrop and "shown" state out of sync.
    this.promptEl.addEventListener("hidden.bs.modal", () => this.modal.show(), { once: true })
    this.promptModal.hide()

    this.postMerge({ dryrun: true, otherUri })
      .then(response => response.json().then(data => ({ ok: response.ok, status: response.status, data })))
      .then(({ ok, status, data }) => {
        if (status === 401) { // session expired or no access: the server set a flash, show it on the redirected page
          this.modal.hide()
          window.location.href = data.redirect_url || window.location.href
          return
        }
        if (!ok || typeof data.message === "undefined") {
          this.modalBody.innerHTML = `<div class='text-danger'>${data.message || "Merge preview failed."}</div>`
          return
        }
        this.modalBody.innerHTML = data.message + (data.rescues || "")
        this.okBtn.disabled = false
        this.okBtn.onclick = () => {
          this.okBtn.disabled = true
          this.modal.hide()
          this.postMerge({ dryrun: false, otherUri })
            .then(response => response.json())
            .then(result => { window.location.href = result.redirect_url || window.location.href })
        }
      })
      .catch(error => {
        this.modalBody.innerHTML = `<div class='text-danger'>Error: ${error.message}</div>`
      })
  }

  postMerge({ dryrun, otherUri }) {
    return fetch("/maintenance/merge_entity", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ uri: this.uriValue, other_uri: otherUri, dryrun })
    })
  }
}
