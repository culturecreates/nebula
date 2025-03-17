import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uri", "button" ]
  static values = { 
    externaluri: String, 
    classtomint: String, 
    label: String,
    authority: String, 
    mintendpoint: String,
    language: String,
    reference: String
  }

  connect() {
    console.log("externaluri", this.externaluriValue)
    console.log("classtomint", this.classtomintValue)
    console.log("label", this.labelValue)
    console.log("authority", this.authorityValue)
    console.log("mintendpoint",  this.mintendpointValue)
    console.log("language", this.languageValue)
    console.log("reference", this.referenceValue)

     // Listen for the custom event
     window.addEventListener('validationFactsLoaded', this.handleValidationData.bind(this))
     this.buttonTarget.disabled = true
  }


  handleValidationData(event) {
    this.facts = event.detail.facts
    console.log("Received validation data:", this.facts)
    this.buttonTarget.disabled = false
  }
  

  async mintEntity() {
    this.buttonTarget.disabled = true
    const url = this.mintendpointValue;
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        "uri": this.externaluriValue,
        "classToMint": this.classtomintValue,
        "publisher": this.authorityValue,
        "name": this.labelValue,
        "language": this.languageValue,
        "reference": this.referenceValue,
        "facts": this.facts
      })
    }
    const res = await fetch(url, options);
    
    const json = await res.json();
    console.log("json", json)

    if (res.status == 500) {
      this.uriTarget.innerHTML = this.createCard("Error", json.message);
      this.buttonTarget.disabled = false
      return
    } 
   
    if (json.status == "success") {
      this.uriTarget.innerHTML = "Successfully minted <a href='" + json.new_uri + "'>" + json.new_uri + "</a>";
    } else {
      this.uriTarget.innerHTML = this.createCard("Failed", json.message);
    }


  }

  createCard(title, message) {
    return `
      <div class="card">
        <div class="card-header">
          ${title}
        </div>
        <div class="card-body">
          <pre>${message}</pre>
        </div>
      </div>
    `;
  }

  
}