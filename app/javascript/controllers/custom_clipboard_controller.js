// filepath: app/javascript/controllers/custom_clipboard_controller.js
import Clipboard from "@stimulus-components/clipboard";

export default class extends Clipboard {
  copy(event) {
    event.preventDefault()

    const text = this.sourceTarget.innerHTML || this.sourceTarget.value
    const unescapedText = this.unescapeText(text);
    navigator.clipboard.writeText(unescapedText).then(() => this.copied())
  }

 unescapeText(text) {
    // Create a temporary DOM element to decode HTML entities
    const tempElement = document.createElement("textarea");
    tempElement.innerHTML = text;
    return tempElement.value;
  }
}