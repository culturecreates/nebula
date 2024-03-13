import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "table" ]

  sort(event) {
    const table = this.tableTarget
    const tbody = table.tBodies[0]
    const th = event.currentTarget
    const index = Array.from(th.parentNode.children).indexOf(th)
    const direction = th.dataset.sortDirection == "asc" ? "desc" : "asc"
    const rows = Array.from(tbody.rows)

     // Remove sort classes from all headers
    for (const header of th.parentNode.children) {
      header.classList.remove("sort-asc", "sort-desc")
    }

    // Add sort class to clicked header
    th.classList.add(`sort-${direction}`)

    rows.sort((rowA, rowB) => {
      const cellA = rowA.cells[index].textContent.trim()
      const cellB = rowB.cells[index].textContent.trim()
    
      // Check if the cells are numbers
      if ((!isNaN(cellA) && !isNaN(cellB)) || 
      (cellA.match(/xsd:integer/) && cellB.match(/xsd:integer/)) ||
      (cellA.match(/xsd:float/) && cellB.match(/xsd:float/)) ) {
        return parseFloat(cellA.replace("xsd:integer", "").replace("xsd:float", "")) - parseFloat(cellB.replace("xsd:integer", "").replace("xsd:float", ""))
      } else {
        return cellA.localeCompare(cellB)
      }
    })

 

    if (direction == "desc") {
      rows.reverse()
    }

    // Renumber the rows
    rows.forEach((row, i) => {
      row.cells[0].textContent = i + 1
    })

    th.dataset.sortDirection = direction

    for (const row of rows) {
      tbody.appendChild(row)
    }
  }
}