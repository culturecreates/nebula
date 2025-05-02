import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  confirm(event) {
    const message = this.element.dataset.confirm || "Are you sure?";
    if (!confirm(message)) {
      event.preventDefault(); // Prevent form submission if the user cancels
    }
  }
}