import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "uri","button" ]

  

  async mintEntity() {
    this.buttonTarget.hidden = true
    const url = "https://api.artsdata.ca/resource.json?uri=K12-382"
    const res = await fetch(url);
    const json = await res.json();
    console.log(this.buttonTargets);
    console.log(json);
    this.uriTarget.innerHTML = json.length + " Results" ;
  }

  
}