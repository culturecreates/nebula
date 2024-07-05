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
        "externalUri": this.externaluriValue,
        "classToMint": this.classtomintValue,
        "publisher": this.authorityValue,
        "name": this.labelValue,
        "language": this.languageValue,
        "reference": this.referenceValue
      })
    }
    const res = await fetch(url, options);
    const json = await res.json();
    console.log(json);
    if (json.data.status == "success") {
      this.uriTarget.innerHTML = "Successfully minted <a href='" + json.new_uri + "'>" + json.new_uri + "</a>";
    } else {
      this.uriTarget.innerHTML = "Error: " + JSON.stringify(json.data.message, null, 2);
    }


  }

  
}