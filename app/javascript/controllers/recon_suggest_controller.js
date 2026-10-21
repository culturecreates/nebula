import { Controller } from "@hotwired/stimulus"

// Generic typeahead for any Reconciliation API v0.2 suggest service
// (https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/#suggest-services).
//
// Targets:
//   input   - visible text field the user types into (not submitted)
//   hidden  - form field that receives the selected id (this is what gets submitted)
//   results - <ul class="dropdown-menu"> the suggestions are rendered into
//   spinner - optional element (hidden by default with d-none) shown while a request is pending
//
// Values:
//   serviceUrl  - suggest service base URL, e.g. "https://wikidata.reconci.link"
//   servicePath - suggest service path, e.g. "/en/suggest/type", "/en/suggest/entity"
//   queryParam  - query string param the service expects the typed text under (default "prefix")
//   minLength   - minimum characters before searching (default 2)
//   timeout     - milliseconds before a suggest request is abandoned (default 5000)
//   debounce    - milliseconds to wait after typing stops before searching (default 300)
//   idPattern   - optional regex (as a string); typed text matching it is written straight
//                 to the hidden field, so a pasted/known id works without picking a suggestion
export default class extends Controller {
  static targets = ["input", "hidden", "results", "spinner"]
  static values = {
    serviceUrl: String,
    servicePath: String,
    queryParam: { type: String, default: "prefix" },
    minLength: { type: Number, default: 2 },
    debounce: { type: Number, default: 300 },
    timeout: { type: Number, default: 5000 },
    idPattern: { type: String, default: "" },
  }

  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)

    if (this.hasHiddenTarget) {
      this.hiddenTarget.addEventListener("change", () => this.syncFromHidden())
      if (this.hiddenTarget.value) this.syncFromHidden()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    clearTimeout(this.searchTimeout)
  }

  search() {
    clearTimeout(this.searchTimeout)
    const query = this.inputTarget.value.trim()

    if (this.idPatternValue && this.hasHiddenTarget && new RegExp(this.idPatternValue).test(query)) {
      this.hiddenTarget.value = query
    }

    if (query.length < this.minLengthValue) {
      this.closeResults()
      return
    }

    this.searchTimeout = setTimeout(() => this.fetchSuggestions(query), this.debounceValue)
  }

  async fetchSuggestions(query) {
    const results = await this.suggest(query)
    if (results === null) {
      this.renderMessage("Suggestions unavailable. You can type a Q-id directly.")
    } else {
      this.renderResults(results)
    }
  }

  // Returns an array of results, or null if the service failed or timed out.
  async suggest(query) {
    const url = new URL(`${this.serviceUrlValue}${this.servicePathValue}`)
    url.searchParams.set(this.queryParamValue, query)

    const controller = new AbortController()
    const timer = setTimeout(() => controller.abort(), this.timeoutValue)
    this.pending = (this.pending || 0) + 1
    this.toggleSpinner(true)

    try {
      const response = await fetch(url, { headers: { Accept: "application/json" }, signal: controller.signal })
      if (!response.ok) return null
      const data = await response.json()
      return data.result || []
    } catch (error) {
      console.error("recon-suggest: suggest request failed", error)
      return null
    } finally {
      clearTimeout(timer)
      this.pending -= 1
      if (this.pending === 0) this.toggleSpinner(false)
    }
  }

  toggleSpinner(show) {
    if (this.hasSpinnerTarget) this.spinnerTarget.classList.toggle("d-none", !show)
  }

  renderMessage(text) {
    if (!this.hasResultsTarget) return

    this.resultsTarget.innerHTML = ""
    const item = document.createElement("li")
    const span = document.createElement("span")
    span.className = "dropdown-item-text text-muted"
    span.textContent = text
    item.appendChild(span)
    this.resultsTarget.appendChild(item)
    this.openResults()
  }

  renderResults(results) {
    if (!this.hasResultsTarget) return

    this.resultsTarget.innerHTML = ""
    results.forEach((result) => {
      const item = document.createElement("li")
      const button = document.createElement("button")
      button.type = "button"
      button.className = "dropdown-item"
      button.dataset.id = result.id
      button.dataset.name = result.name
      button.dataset.action = "click->recon-suggest#select"
      button.textContent = `${result.name} (${result.id})`
      item.appendChild(button)
      this.resultsTarget.appendChild(item)
    })

    results.length > 0 ? this.openResults() : this.closeResults()
  }

  select(event) {
    const { id, name } = event.currentTarget.dataset
    this.setDisplay(id, name)
    this.closeResults()
    if (this.hasHiddenTarget) this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  // Re-renders the display text after something outside this controller
  // (e.g. another controller) sets the hidden field's value directly.
  async syncFromHidden() {
    const id = this.hiddenTarget.value
    if (!id || this.inputTarget.value.endsWith(`(${id})`)) return

    // Known label (e.g. chosen before a form submit reloaded the page): no request needed.
    const cached = this.cachedName(id)
    if (cached) {
      this.setDisplay(id, cached)
      return
    }

    const results = await this.suggest(id)
    const match = (results || []).find((result) => result.id === id)
    this.setDisplay(id, match ? match.name : id)
  }

  cacheKey(id) {
    return `recon-suggest:${this.serviceUrlValue}${this.servicePathValue}:${id}`
  }

  cachedName(id) {
    try {
      return sessionStorage.getItem(this.cacheKey(id))
    } catch (error) {
      return null
    }
  }

  cacheName(id, name) {
    try {
      sessionStorage.setItem(this.cacheKey(id), name)
    } catch (error) {
      // storage unavailable; the label will just be looked up again
    }
  }

  setDisplay(id, name) {
    if (name !== id) this.cacheName(id, name)
    this.inputTarget.value = name === id ? id : `${name} (${id})`
    if (this.hasHiddenTarget) this.hiddenTarget.value = id
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.closeResults()
  }

  closeResults() {
    if (this.hasResultsTarget) this.resultsTarget.classList.remove("show")
  }

  openResults() {
    if (this.hasResultsTarget) this.resultsTarget.classList.add("show")
  }
}
