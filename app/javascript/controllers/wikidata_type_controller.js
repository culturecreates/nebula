import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabType", "typeField"]

  connect() {
    this.updateTypeFromSelectedTab()
  }

  updateType(event) {
    this.typeFieldTarget.value = event.target.value
    this.typeFieldTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  updateTypeFromSelectedTab() {
    const selectedTab = this.tabTypeTargets.find((tabType) => tabType.checked)
    if (selectedTab && this.hasTypeFieldTarget) {
      this.typeFieldTarget.value = selectedTab.value
    }
  }
}
