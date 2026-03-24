document.addEventListener('turbo:load', function() {
  document.querySelectorAll('.change-on-click').forEach(function(div) {
    div.addEventListener('click', function(event) {
      console.log("Clicked on div with predicate hash: " + div.dataset.predicateHash);
      const predicateHash = div.dataset.predicateHash;
      if (!predicateHash) return;
      const targetDiv = document.getElementById('property-claims-div-' + predicateHash);
      if (targetDiv) {
        targetDiv.classList.toggle('d-none');
      }
      const icon = div.querySelector('i');
      if (icon) {
        if (icon.classList.contains('text-secondary')) {
          icon.classList.remove('text-secondary');
          icon.classList.add('text-info-subtle');
        } else {
          icon.classList.remove('text-info-subtle');
          icon.classList.add('text-secondary');
        }
      }
    });
  });
});