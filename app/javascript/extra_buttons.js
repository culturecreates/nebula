document.addEventListener('turbo:load', function() {
  document.querySelectorAll('.change-on-click-link').forEach(function(link) {
    link.addEventListener('click', function(event) {
      link.querySelector('i').classList.remove('text-secondary');
      link.querySelector('i').classList.add('text-primary');
    });
  });
});