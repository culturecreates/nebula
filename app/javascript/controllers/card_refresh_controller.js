import { Controller } from "@hotwired/stimulus"

// The clicked link's own frame gets replaced wholesale once the refreshed
// card response arrives, so the spinning icon is torn down along with it -
// no need to manually stop the animation.
export default class extends Controller {
  static targets = ["icon"]

  spin() {
    this.iconTarget.classList.add("fa-spin")
  }
}
