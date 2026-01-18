// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("click", (event) => {
  const row = event.target.closest("[data-url]")
  if (row) {
    window.location = row.dataset.url
  }
})