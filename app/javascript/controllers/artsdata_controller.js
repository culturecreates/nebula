import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uri", "button" ]
  static values = { externaluri: String, classtomint: String, authority: String}

  connect() {
    console.log(this.externaluriValue); // logs the value of @your_variable
  }

  async mintEntity() {
    this.buttonTarget.disabled = true
    const url = 'https://api.artsdata.ca/mint';
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        "externalUri": this.externaluriValue,
        "classToMint": this.classtomintValue,
        "publisher": this.authorityValue
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