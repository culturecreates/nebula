import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static values = { uri: String }

  connect() {
    this.modal = new bootstrap.Modal(document.getElementById("dryrunModal"))
    this.modalBody = document.getElementById("dryrunModalBody")
    this.okBtn = document.getElementById("dryrunModalOk")
    this.okBtn.disabled = true // Disable the update button at first
  }

  refresh(event) {
    event.preventDefault()
    this.modalBody.innerHTML = "<div class='text-center'><span class='spinner-border spinner-border-sm' role='status' aria-hidden='true'></span> Calculating...</div>"
    this.okBtn.disabled = true // Ensure button is disabled on each refresh
    this.modal.show()

    fetch("/maintenance/refresh_entity", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ uri: this.uriValue, dryrun: true })
    })
      .then(async response => {
        let data = null;
        try {
          data = await response.json();
        } catch (e) {}
        if (!response.ok) {
          let msg = data && data.message ? `${data.message}` : '';
          this.modalBody.innerHTML = `Failed to preview. ${msg ? msg : 'Please try again later.'}`;
          this.okBtn.disabled = true;
          return null;
        }
        return data;
      })
      .then(data => {
        if (!data) return;
        if (typeof data.message === "undefined") {
          this.modal.hide();
          window.location.reload();
          return;
        }
        this.modalBody.innerHTML = data.message;
        this.okBtn.disabled = false; // Enable the update button if fetch is successful
        this.okBtn.onclick = () => {
          this.modal.hide();
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
              window.location.href = result.redirect_url;
            });
        };
      });
  }
}
