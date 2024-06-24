import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result", "button" ]
  static values = { 
    token: String, 
    url: String
  }

  connect() {
    console.log("token", this.tokenValue)
    console.log("url", this.urlValue)
  }

  async runAction() {
    this.buttonTarget.disabled = true
   // const url = this.urlValue;
   const url = "https://api.github.com/repos/culturecreates/artsdata-google-workspace-smart-chip/actions/workflows/push-to-artsdata.yml/dispatches"
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + this.tokenValue,
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28'
      },
      body: JSON.stringify({
        'ref': 'main'
      })
    }
    const res = await fetch(url, options);
    console.log("res=", res);
    const json = await res.json();
    console.log("res.json()=", json);
    if (json.status == "204") {
      this.resultTarget.innerHTML = "Successfully triggered the action";
    } else {
      this.resultTarget.innerHTML = "Error: " + JSON.stringify(json, null, 2);
    }


  }

  
}