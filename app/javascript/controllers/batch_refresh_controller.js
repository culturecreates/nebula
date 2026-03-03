import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  connect() {
    const modalEl = document.getElementById("batchRefreshModal")
    if (modalEl) {
      this.modal = new bootstrap.Modal(modalEl)
      this.modalBody = document.getElementById("batchRefreshModalBody")
      this.okBtn = document.getElementById("batchRefreshModalOk")
    }
  }

  refresh(event) {
    event.preventDefault()
    if (!this.modal) return

    const uris = this.collectArtsdataUris()

    if (uris.length === 0) {
      alert("No Artsdata URIs found in visible rows.")
      return
    }

    const displayUris = uris.slice(0, 10)
    let html = `<p><strong>Total entities to refresh: ${uris.length}</strong></p><ul>`
    displayUris.forEach(uri => {
      html += `<li>${uri}</li>`
    })
    html += `</ul>`
    if (uris.length > 10) {
      html += `<p>...and ${uris.length - 10} more.</p>`
    }

    this.modalBody.innerHTML = html
    this.okBtn.onclick = () => {
      this.modal.hide()
      fetch("/maintenance/batch_refresh_entity", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
        },
        body: JSON.stringify({ uris: uris, redirect_url: window.location.href })
      })
        .then(response => response.json())
        .then(result => {
          window.location.href = result.redirect_url
        })
        .catch(error => {
          alert("Error: " + error.message)
        })
    }

    this.modal.show()
  }

  collectArtsdataUris() {
    const rows = document.querySelectorAll('[data-filter-query-results-target="content"]')
    const uris = new Set()
    rows.forEach(row => {
      if (row.style.display === "none") return
      row.querySelectorAll('[data-clipboard-target="source"]').forEach(span => {
        const uri = span.textContent.trim()
        if (uri.startsWith("http://kg.artsdata.ca/resource/K")) {
          uris.add(uri)
        }
      })
    })
    return Array.from(uris)
  }
}
