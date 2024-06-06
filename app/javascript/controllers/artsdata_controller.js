import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uri", "button" ]
  static values = { 
    externaluri: String, 
    classtomint: String, 
    authority: String, 
    mintEndpoint: String,
    name: String,
    language: String,
    reference: String
  }

  connect() {
    console.log(this.externaluriValue, this.mintEndpointValue); // logs the value of @your_variable
  }

  async mintEntity() {
    this.buttonTarget.disabled = true
    const url = this.mintEndpointValue;
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        "externalUri": this.externaluriValue,
        "classToMint": this.classtomintValue,
        "publisher": this.authorityValue,
        "name": this.nameValue,
        "language": this.languageValue,
        "reference": this.referenceValue
      })
    }
    const res = await fetch(url, options);
    const json = await res.json();
    console.log(json);
    if (json.data.status == "success") {
      this.uriTarget.innerHTML = "Successfully minted";
    } else {
      this.uriTarget.innerHTML = "Error: " + JSON.stringify(json.data.message, null, 2);
    }


  }

  
}