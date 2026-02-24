import { Controller } from "@hotwired/stimulus"

const SPARQL_ENDPOINT = "https://db.artsdata.ca/repositories/artsdata"

const GEOJSON_URL =
  "https://raw.githubusercontent.com/codeforgermany/click_that_hood/main/public/data/canada.geojson"

// Map all known province/territory variants to canonical two-letter codes
const PROVINCE_ALIASES = {
  // Two-letter codes
  AB: "AB", BC: "BC", MB: "MB", NB: "NB", NL: "NL", NS: "NS",
  NT: "NT", NU: "NU", ON: "ON", PE: "PE", QC: "QC",
  SK: "SK", YT: "YT",
  // Common variants
  YK: "YT", "(QC)": "QC", PEI: "PE",
  // English names
  "Alberta": "AB",
  "British Columbia": "BC",
  "Manitoba": "MB",
  "New Brunswick": "NB",
  "Newfoundland and Labrador": "NL",
  "Newfoundland": "NL",
  "Nova Scotia": "NS",
  "Northwest Territories": "NT",
  "Nunavut": "NU",
  "Ontario": "ON",
  "Prince Edward Island": "PE",
  "Quebec": "QC",
  "Saskatchewan": "SK",
  "Yukon": "YT",
  // French names
  "Québec": "QC",
  "Nouveau-Brunswick": "NB",
  "Nouvelle-Écosse": "NS",
  "Île-du-Prince-Édouard": "PE",
  "Colombie-Britannique": "BC",
  "Terre-Neuve-et-Labrador": "NL",
  "Territoires du Nord-Ouest": "NT",
  "Territoire du Yukon": "YT",
}

// Map GeoJSON feature names to province codes
const GEOJSON_NAME_TO_CODE = {
  "Alberta": "AB",
  "British Columbia": "BC",
  "Manitoba": "MB",
  "New Brunswick": "NB",
  "Newfoundland and Labrador": "NL",
  "Nova Scotia": "NS",
  "Northwest Territories": "NT",
  "Nunavut": "NU",
  "Ontario": "ON",
  "Prince Edward Island": "PE",
  "Quebec": "QC",
  "Saskatchewan": "SK",
  "Yukon Territory": "YT",
  "Yukon": "YT",
}

// Full display names for provinces/territories
const PROVINCE_NAMES = {
  AB: "Alberta",
  BC: "British Columbia",
  MB: "Manitoba",
  NB: "New Brunswick",
  NL: "Newfoundland and Labrador",
  NS: "Nova Scotia",
  NT: "Northwest Territories",
  NU: "Nunavut",
  ON: "Ontario",
  PE: "Prince Edward Island",
  QC: "Quebec",
  SK: "Saskatchewan",
  YT: "Yukon",
}

export default class extends Controller {
  static targets = ["map", "loading", "tooltip"]

  connect() {
    this.waitForD3().then(() => this.loadData())
  }

  waitForD3() {
    return new Promise((resolve) => {
      if (typeof d3 !== "undefined") return resolve()
      const check = setInterval(() => {
        if (typeof d3 !== "undefined") {
          clearInterval(check)
          resolve()
        }
      }, 50)
    })
  }

  async loadData() {
    try {
      const [geojson, counts] = await Promise.all([
        this.fetchGeoJSON(),
        this.fetchEventCounts()
      ])
      this.loadingTarget.style.display = "none"
      this.renderMap(geojson, counts)
    } catch (error) {
      console.error("Events map error:", error)
      this.loadingTarget.innerHTML =
        `<p class="text-danger">Failed to load data: ${error.message}</p>`
    }
  }

  async fetchGeoJSON() {
    const response = await fetch(GEOJSON_URL)
    if (!response.ok) throw new Error(`GeoJSON fetch failed: ${response.status}`)
    return response.json()
  }

  async fetchEventCounts() {
    const query = `
      PREFIX schema: <http://schema.org/>
      SELECT ?province (COUNT(DISTINCT ?event) AS ?count) WHERE {
        ?event a schema:Event .
        ?event schema:location ?location .
        ?location schema:address ?address .
        ?address schema:addressRegion ?province .
      }
      GROUP BY ?province
      ORDER BY DESC(?count)
    `
    const url = `${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`
    const response = await fetch(url, {
      headers: { Accept: "application/sparql-results+json" }
    })
    if (!response.ok) throw new Error(`SPARQL query failed: ${response.status}`)
    const data = await response.json()

    // Aggregate counts by normalized province code
    const counts = {}
    for (const b of data.results.bindings) {
      const raw = b.province.value.trim()
      const code = PROVINCE_ALIASES[raw]
      if (!code) continue // skip non-Canadian entries
      const count = parseInt(b.count.value, 10)
      counts[code] = (counts[code] || 0) + count
    }
    return counts
  }

  renderMap(geojson, counts) {
    const width = Math.min(1100, window.innerWidth - 20)
    const height = width * 0.7

    const projection = d3.geoConicConformal()
      .center([0, 62])
      .rotate([96, 0])
      .parallels([49, 77])
      .scale(width * 0.7)
      .translate([width / 2, height / 2])

    const path = d3.geoPath().projection(projection)

    const maxCount = Math.max(...Object.values(counts), 1)
    const colorScale = d3.scaleSequential(d3.interpolateBlues)
      .domain([0, maxCount])

    const svg = d3.select(this.mapTarget)
      .append("svg")
      .attr("viewBox", `0 0 ${width} ${height}`)
      .attr("width", width)
      .attr("height", height)
      .style("background", "#fafafa")

    const g = svg.append("g")

    // Draw provinces
    g.selectAll("path")
      .data(geojson.features)
      .join("path")
      .attr("d", path)
      .attr("fill", d => {
        const code = GEOJSON_NAME_TO_CODE[d.properties.name]
        const count = code ? (counts[code] || 0) : 0
        return count > 0 ? colorScale(count) : "#e8e8e8"
      })
      .attr("stroke", "#fff")
      .attr("stroke-width", 1)
      .style("cursor", "pointer")
      .on("mouseover", (event, d) => {
        d3.select(event.currentTarget)
          .attr("stroke", "#333")
          .attr("stroke-width", 2)
        this.showTooltip(event, d.properties.name, counts)
      })
      .on("mousemove", (event) => {
        this.moveTooltip(event)
      })
      .on("mouseout", (event) => {
        d3.select(event.currentTarget)
          .attr("stroke", "#fff")
          .attr("stroke-width", 1)
        this.hideTooltip()
      })

    // Add count labels at centroids
    g.selectAll("text")
      .data(geojson.features)
      .join("text")
      .attr("transform", d => {
        const centroid = path.centroid(d)
        return `translate(${centroid[0]}, ${centroid[1]})`
      })
      .attr("text-anchor", "middle")
      .attr("dy", "0.35em")
      .style("font-size", "11px")
      .style("font-weight", "600")
      .style("fill", d => {
        const code = GEOJSON_NAME_TO_CODE[d.properties.name]
        const count = code ? (counts[code] || 0) : 0
        return count > maxCount * 0.5 ? "#fff" : "#333"
      })
      .style("pointer-events", "none")
      .text(d => {
        const code = GEOJSON_NAME_TO_CODE[d.properties.name]
        const count = code ? (counts[code] || 0) : 0
        return count > 0 ? count.toLocaleString() : ""
      })
  }

  showTooltip(event, geoName, counts) {
    const code = GEOJSON_NAME_TO_CODE[geoName]
    const name = code ? PROVINCE_NAMES[code] : geoName
    const count = code ? (counts[code] || 0) : 0
    const tooltip = this.tooltipTarget

    // Clear any existing tooltip content
    while (tooltip.firstChild) {
      tooltip.removeChild(tooltip.firstChild)
    }

    // Build tooltip content safely using DOM APIs
    const nameDiv = document.createElement("div")
    nameDiv.className = "tooltip-name"
    nameDiv.textContent = name

    const countDiv = document.createElement("div")
    countDiv.className = "tooltip-count"
    countDiv.textContent = `${count.toLocaleString()} events`

    tooltip.appendChild(nameDiv)
    tooltip.appendChild(countDiv)
    tooltip.style.display = "block"
    this.moveTooltip(event)
  }

  moveTooltip(event) {
    const tooltip = this.tooltipTarget
    tooltip.style.left = `${event.clientX + 12}px`
    tooltip.style.top = `${event.clientY - 28}px`
  }

  hideTooltip() {
    this.tooltipTarget.style.display = "none"
  }
}
