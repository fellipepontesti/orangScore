function validatePasswordsAndContinue () {
  const password = document.getElementById('password')
  const confirmation = document.getElementById('password_confirmation')

  // limpa estados anteriores
  password.setCustomValidity('')
  confirmation.setCustomValidity('')

  if (password.value !== confirmation.value) {
    // ativa validação nativa
    confirmation.setCustomValidity('As senhas não coincidem')

    // força o browser a mostrar o erro
    confirmation.reportValidity()
    return
  }

  // se passou, avança
  nextStep()
}
