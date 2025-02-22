import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterInput", "content"]

  // Is this needed?
  connect() {
    this.filterInputTarget.addEventListener('keypress', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault();
      }
    });
  }

  filterContents() {
    const query = this.filterInputTarget.value.toLowerCase();
    console.log(this.contentTargets);
    this.contentTargets.forEach(content => {
      const text = content.textContent.toLowerCase();
      content.style.display = text.includes(query) ? "" : "none";
    });
    console.log(query);
  }
}