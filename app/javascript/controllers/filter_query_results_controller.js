import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["filterInput", "content", "table"]

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
    this.contentTargets.forEach(content => {
      const text = content.textContent.toLowerCase();
      content.style.display = text.includes(query) ? "" : "none";
    });
    this.redrawTable();
  }

  redrawTable() {
    // Trigger a redraw of the table
    const table = this.tableTarget;
    table.style.display = 'none';
    table.offsetHeight; // Trigger reflow
    table.style.display = '';
  }
}