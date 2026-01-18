module LigasHelper
  def role_icon(role)
    {
      'owner'  => '👑',
      'admin'  => '🛡️',
      'member' => '👤'
    }[role]
  end

  def status_icon(status)
    {
      'invited'          => '⏳',
      'accepted'         => '✅',
      'pending_deletion' => '⚠️'
    }[status]
  end
end
