module UsersHelper
  def conta_confirmada?(user)
    user.confirmed? || user.provider.present?
  end

  def conta_status_badge(user)
    if conta_confirmada?(user)
      if user.provider.present?
        tag.span("Google ✓", class: "badge badge-info badge-sm font-bold")
      else
        tag.span("Confirmado ✓", class: "badge badge-success badge-sm font-bold")
      end
    else
      tag.span("E-mail pendente", class: "badge badge-warning badge-sm font-bold")
    end
  end

  def login_count_label(user)
    count = user.sign_in_count.to_i
    "#{count} #{count == 1 ? 'login' : 'logins'}"
  end
end
