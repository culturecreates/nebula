import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static values = { uri: String }

  connect() {
    this.modal = new bootstrap.Modal(document.getElementById("dryrunModal"))
    this.modalBody = document.getElementById("dryrunModalBody")
    this.okBtn = document.getElementById("dryrunModalOk")
  }

  refresh(event) {
    event.preventDefault()
    this.modalBody.innerHTML = "<div class='text-center'><span class='spinner-border spinner-border-sm' role='status' aria-hidden='true'></span> Calculating...</div>"
    this.modal.show()

    fetch("/maintenance/refresh_entity", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ uri: this.uriValue, dryrun: true })
    })
      .then(response => response.json())
      .then(data => {
        if (typeof data.message === "undefined") {
          this.modal.hide()
          window.location.reload()
          return
        }
        this.modalBody.innerHTML = data.message
        this.okBtn.onclick = () => {
          this.modal.hide()
          fetch("/maintenance/refresh_entity", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({ uri: this.uriValue, dryrun: false })
          })
            .then(response => response.json())
            .then(result => {
              window.location.href = result.redirect_url
            })
        }
      })
  }
}
