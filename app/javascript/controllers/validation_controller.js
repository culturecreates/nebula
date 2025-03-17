import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    facts: String
  }
  connect() {
    console.log("facts",  JSON.parse(this.factsValue))
    if (this.factsValue != "[]") {
      this.sendFacts()
    }
  }
   

  sendFacts() {
    const event = new CustomEvent('validationFactsLoaded', {
      detail: { facts: this.factsValue }
    })
    console.log("Sending facts", event)
    window.dispatchEvent(event)
  }

}