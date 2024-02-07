

document.addEventListener('turbo:load', () => {
  console.log('Turbo has loaded the page');

  document.addEventListener('turbo:before-cache', () => {
    console.log("turbo:before-cache")
    const flashMessages = document.querySelectorAll('.flash');
    flashMessages.forEach((flashMessage) => {
      flashMessage.remove();
    });
  });
});