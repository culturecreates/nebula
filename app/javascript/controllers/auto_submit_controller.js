import { Controller } from "@hotwired/stimulus"

// Submits the form as soon as one of its fields changes,
// e.g. <select data-action="change->auto-submit#submit">
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
