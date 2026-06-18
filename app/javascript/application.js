// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("click", (event) => {
  const row = event.target.closest("[data-url]")
  if (row) {
    window.location = row.dataset.url
  }
})

// Força o reload da página se ela for carregada a partir do cache de histórico (BFCache)
// prevenindo problemas de CSRF expirado no celular após logouts ou retornos de página.
window.addEventListener("pageshow", (event) => {
  if (event.persisted) {
    window.location.reload()
  }
})