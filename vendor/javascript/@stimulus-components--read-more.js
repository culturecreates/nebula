// @stimulus-components/read-more@5.0.0 downloaded from https://ga.jspm.io/npm:@stimulus-components/read-more@5.0.0/dist/stimulus-read-more.mjs

import{Controller as e}from"@hotwired/stimulus";const t=class _ReadMore extends e{connect(){this.open=!1}toggle(e){this.open===!1?this.show(e):this.hide(e)}show(e){this.open=!0;const t=e.target;t.innerHTML=this.lessTextValue,this.contentTarget.style.setProperty("--read-more-line-clamp","'unset'")}hide(e){this.open=!1;const t=e.target;t.innerHTML=this.moreTextValue,this.contentTarget.style.removeProperty("--read-more-line-clamp")}};t.targets=["content"],t.values={moreText:String,lessText:String};let s=t;export{s as default};

