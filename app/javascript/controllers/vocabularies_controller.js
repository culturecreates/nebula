import { Controller } from "@hotwired/stimulus"

const SPARQL_ENDPOINT = "https://db.artsdata.ca/repositories/artsdata"
const ARTSDATA_PREFIX = "http://kg.artsdata.ca/resource"

const SCHEME_COLORS = {
  ArtsdataEventTypes: "#4e79a7",
  ArtsdataGenres: "#f28e2b",
  ArtsdataOrganizationTypes: "#e15759",
  ArtsdataMembership: "#76b7b2",
  ArtsdataPlaceTypes: "#59a14f"
}

const I18N = {
  en: {
    title: "Artsdata SKOS Controlled Vocabularies",
    subtitle: "Click a circle to zoom in. Click outside to zoom out.",
    loading: "Fetching vocabularies from Artsdata...",
    rootName: "Artsdata Vocabularies",
    deprecated: "deprecated"
  },
  fr: {
    title: "Vocabulaires contr\u00f4l\u00e9s SKOS d'Artsdata",
    subtitle: "Cliquez sur un cercle pour zoomer. Cliquez \u00e0 l'ext\u00e9rieur pour d\u00e9zoomer.",
    loading: "R\u00e9cup\u00e9ration des vocabulaires d'Artsdata...",
    rootName: "Vocabulaires Artsdata",
    deprecated: "obsol\u00e8te"
  }
}

export default class extends Controller {
  static targets = ["chart", "loading", "tooltip", "title", "subtitle", "enBtn", "frBtn"]
  static values = { lang: { type: String, default: "en" } }

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

  switchLang(event) {
    const lang = event.currentTarget.dataset.lang
    if (lang === this.langValue) return

    this.langValue = lang
    this.enBtnTarget.classList.toggle("active", lang === "en")
    this.frBtnTarget.classList.toggle("active", lang === "fr")

    const t = I18N[lang]
    this.titleTarget.textContent = t.title
    this.subtitleTarget.textContent = t.subtitle

    this.chartTarget.innerHTML = ""
    this.loadingTarget.style.display = "block"
    this.loadingTarget.innerHTML = `
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
      <p class="mt-2 text-muted">${t.loading}</p>
    `
    this.loadData()
  }

  async loadData() {
    try {
      const lang = this.langValue
      const [schemes, concepts] = await Promise.all([
        this.fetchSchemes(lang),
        this.fetchConcepts(lang)
      ])
      const hierarchy = this.buildHierarchy(schemes, concepts)
      this.loadingTarget.style.display = "none"
      this.renderChart(hierarchy)
    } catch (error) {
      console.error("Vocabularies error:", error)
      this.loadingTarget.style.display = "block"
      this.loadingTarget.innerHTML =
        `<p class="text-danger">Failed to load data: ${error.message}</p>`
    }
  }

  async sparqlQuery(query) {
    const url = `${SPARQL_ENDPOINT}?query=${encodeURIComponent(query)}`
    const response = await fetch(url, {
      headers: { Accept: "application/sparql-results+json" }
    })
    if (!response.ok) throw new Error(`SPARQL query failed: ${response.status}`)
    return response.json()
  }

  async fetchSchemes(lang) {
    const query = `
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      SELECT ?scheme ?label WHERE {
        ?scheme a skos:ConceptScheme .
        FILTER(STRSTARTS(STR(?scheme), "${ARTSDATA_PREFIX}"))
        OPTIONAL {
          ?scheme skos:prefLabel ?label .
          FILTER(lang(?label) = "${lang}")
        }
      }
    `
    const result = await this.sparqlQuery(query)
    return result.results.bindings.map(b => ({
      uri: b.scheme.value,
      label: b.label ? b.label.value : this.displayName(b.scheme.value)
    }))
  }

  async fetchConcepts(lang) {
    const query = `
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX owl: <http://www.w3.org/2002/07/owl#>
      SELECT ?concept ?label ?definition ?broader ?scheme ?deprecated WHERE {
        ?concept skos:inScheme ?scheme .
        FILTER(STRSTARTS(STR(?scheme), "${ARTSDATA_PREFIX}"))
        FILTER NOT EXISTS { ?concept a skos:Collection }
        OPTIONAL {
          ?concept skos:prefLabel ?label .
          FILTER(lang(?label) = "${lang}")
        }
        OPTIONAL {
          ?concept skos:definition ?definition .
          FILTER(lang(?definition) = "${lang}")
        }
        OPTIONAL { ?concept skos:broader ?broader }
        OPTIONAL { ?concept owl:deprecated ?deprecated }
      }
    `
    const result = await this.sparqlQuery(query)
    return result.results.bindings.map(b => ({
      uri: b.concept.value,
      label: b.label ? b.label.value : this.displayName(b.concept.value),
      definition: b.definition ? b.definition.value : null,
      broader: b.broader ? b.broader.value : null,
      scheme: b.scheme.value,
      deprecated: b.deprecated ? b.deprecated.value === "true" : false
    }))
  }

  localName(uri) {
    return uri.split("/").pop()
  }

  displayName(uri) {
    return this.localName(uri).replace(/([A-Z])/g, " $1").trim()
  }

  buildHierarchy(schemes, concepts) {
    const t = I18N[this.langValue]
    const root = { name: t.rootName, uri: ARTSDATA_PREFIX, children: [] }

    for (const scheme of schemes) {
      const schemeKey = this.localName(scheme.uri)
      const schemeConcepts = concepts.filter(c => c.scheme === scheme.uri)

      // Deduplicate and index concepts by URI
      const conceptMap = new Map()
      for (const c of schemeConcepts) {
        if (!conceptMap.has(c.uri)) {
          conceptMap.set(c.uri, {
            name: c.deprecated ? `${c.label} (${t.deprecated})` : c.label,
            uri: c.uri,
            definition: c.definition,
            deprecated: c.deprecated,
            children: [],
            broader: c.broader
          })
        }
      }

      // Build parent-child relationships
      const rootConcepts = new Map()
      for (const [uri, node] of conceptMap) {
        if (node.broader && conceptMap.has(node.broader)) {
          const parent = conceptMap.get(node.broader)
          if (!parent.children.find(ch => ch.uri === uri)) {
            parent.children.push(node)
          }
        } else {
          rootConcepts.set(uri, node)
        }
      }

      // Clean up the broader property and assign leaf values
      const cleanNode = (node) => {
        delete node.broader
        if (node.children.length === 0) {
          delete node.children
          node.value = 1
        } else {
          node.children.forEach(cleanNode)
        }
      }

      const children = Array.from(rootConcepts.values())
      children.forEach(cleanNode)

      root.children.push({
        name: scheme.label,
        uri: scheme.uri,
        schemeKey,
        children
      })
    }

    return root
  }

  renderChart(data) {
    const width = Math.min(960, window.innerWidth - 20)
    const height = width

    const hierarchy = d3.hierarchy(data)
      .sum(d => d.value || 0)
      .sort((a, b) => (b.value || 0) - (a.value || 0))

    const pack = d3.pack()
      .size([width, height])
      .padding(3)

    const root = pack(hierarchy)

    let focus = root
    let view

    const schemeColor = (d) => {
      let node = d
      while (node.depth > 1) node = node.parent
      if (node.depth === 1 && node.data.schemeKey) {
        return SCHEME_COLORS[node.data.schemeKey] || "#999"
      }
      return "#ccc"
    }

    const fillColor = (d) => {
      if (d.depth === 0) return "#eee"
      const base = d3.hsl(schemeColor(d))
      let color
      if (!d.children) {
        color = base.brighter(0.8)
      } else {
        const t = (d.depth - 1) / Math.max(root.height - 1, 1)
        color = d3.hsl(d3.interpolateRgb(base.brighter(1.5), base.darker(0.3))(t))
      }
      if (d.data.deprecated) {
        color.s *= 0.25
        color.l = Math.min(color.l + 0.3, 0.92)
      }
      return color.toString()
    }

    const svg = d3.select(this.chartTarget)
      .append("svg")
      .attr("viewBox", `-${width / 2} -${height / 2} ${width} ${height}`)
      .attr("width", width)
      .attr("height", height)
      .style("background", "#fafafa")
      .on("click", () => zoom(root))

    const node = svg.append("g")
      .selectAll("circle")
      .data(root.descendants().slice(1))
      .join("circle")
      .attr("fill", d => fillColor(d))
      .attr("fill-opacity", d => d.children ? 0.6 : 0.9)
      .attr("stroke", d => {
        if (!d.children) return "none"
        const s = d3.rgb(schemeColor(d)).darker(0.5)
        return d.data.deprecated ? d3.rgb(s).brighter(1.5).toString() : s
      })
      .attr("stroke-width", d => d.children ? 1.5 : 0)
      .style("cursor", "pointer")
      .on("mouseover", (event, d) => {
        this.showTooltip(event, d.data)
        d3.select(event.currentTarget).attr("fill-opacity", 1)
      })
      .on("mousemove", (event) => {
        this.moveTooltip(event)
      })
      .on("mouseout", (event, d) => {
        this.hideTooltip()
        d3.select(event.currentTarget)
          .attr("fill-opacity", d.children ? 0.6 : 0.9)
      })
      .on("click", (event, d) => {
        if (focus !== d) {
          zoom(d)
          event.stopPropagation()
        }
      })

    const label = svg.append("g")
      .attr("text-anchor", "middle")
      .selectAll("text")
      .data(root.descendants())
      .join("text")
      .style("font-family", "sans-serif")
      .style("font-size", d => {
        if (d.depth === 0) return "16px"
        if (d.depth === 1) return "12px"
        return "10px"
      })
      .style("font-weight", d => d.depth <= 1 ? "600" : "400")
      .style("fill", "#222")
      .style("fill-opacity", d => d.parent === root ? 1 : 0)
      .style("display", d => d.parent === root ? "inline" : "none")
      .text(d => d.data.name)

    zoomTo([root.x, root.y, root.r * 2])

    function zoomTo(v) {
      const k = width / v[2]
      view = v
      label.attr("transform", d =>
        `translate(${(d.x - v[0]) * k},${(d.y - v[1]) * k})`
      )
      node.attr("transform", d =>
        `translate(${(d.x - v[0]) * k},${(d.y - v[1]) * k})`
      )
      node.attr("r", d => d.r * k)
    }

    function zoom(d) {
      focus = d
      const transition = svg.transition()
        .duration(750)
        .tween("zoom", () => {
          const i = d3.interpolateZoom(view, [focus.x, focus.y, focus.r * 2])
          return t => zoomTo(i(t))
        })

      label
        .filter(function (d) {
          return d.parent === focus || this.style.display === "inline"
        })
        .transition(transition)
        .style("fill-opacity", d => d.parent === focus ? 1 : 0)
        .on("start", function (d) {
          if (d.parent === focus) this.style.display = "inline"
        })
        .on("end", function (d) {
          if (d.parent !== focus) this.style.display = "none"
        })
    }
  }

  showTooltip(event, data) {
    const tooltip = this.tooltipTarget

    // Clear any existing tooltip content safely
    while (tooltip.firstChild) {
      tooltip.removeChild(tooltip.firstChild)
    }

    // Label
    const labelDiv = document.createElement("div")
    labelDiv.className = "tooltip-label"
    labelDiv.textContent = data.name || ""
    tooltip.appendChild(labelDiv)

    // Optional description
    if (data.definition) {
      const descDiv = document.createElement("div")
      descDiv.className = "tooltip-desc"
      descDiv.textContent = data.definition
      tooltip.appendChild(descDiv)
    }

    // URI
    const uriDiv = document.createElement("div")
    uriDiv.className = "tooltip-uri"
    uriDiv.textContent = data.uri || ""
    tooltip.appendChild(uriDiv)

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
