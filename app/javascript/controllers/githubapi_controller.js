import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["result", "button" ]
  static values = { 
    token: String, 
    url: String,
    method: String,
    httpbody: String
  }

  connect() {
    console.log("token", this.tokenValue)
    console.log("url", this.urlValue)
    console.log("httpMethod", this.methodValue)
    console.log("httpBody", this.httpbodyValue)
  }

  async runAction() {
    this.buttonTarget.disabled = true
    const url = this.urlValue;
    const httpMethod = this.methodValue ||= "GET";
    const httpBody = this.httpbodyValue ||= "{'ref': 'main'}";
    // const url = "https://api.github.com/repos/culturecreates/artsdata-google-workspace-smart-chip/actions/workflows/push-to-artsdata.yml/dispatches"
    const options = {
      method: httpMethod,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + this.tokenValue,
        'Accept': 'application/vnd.github.v3+json',
        'X-GitHub-Api-Version': '2022-11-28'
      }
    }
    // todo: make this more generic
    if (httpMethod == "POST") {
      options.body = httpBody;
    }
    try {
      const res = await fetch(url, options);
      if (!res.ok) {
        throw new Error(`HTTP error! status: ${res.status}`);
      }
      console.log("res:", res);
     
      if (res.status == 204) {
        this.resultTarget.innerHTML = "Successfully ran the action. " + JSON.stringify(res, null, 2);
      } else {
        this.resultTarget.innerHTML = JSON.stringify(res, null, 2);
      }
    } catch (error) {
      console.error('Fetch error:', error);
      this.resultTarget.innerHTML = error.message;
    }
  }

  
}