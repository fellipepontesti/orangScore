module LigasHelper
  def role_icon(role)
    {
      'owner'  => '<span class="text-primary font-black" title="Capitão">Ⓒ</span>',
      'admin'  => '<span class="badge badge-sm bg-blue-500/20 text-blue-400 border-none font-bold px-2 py-0.5 rounded text-[10px]">ADM</span>',
      'member' => ''
    }[role].html_safe
  end

  def rank_badge(index)
    case index
    when 0
      '<span class="flex items-center justify-center w-8 h-8 rounded-full bg-yellow-400 text-yellow-900 font-bold text-xs shadow-lg shadow-yellow-500/50" title="1º Lugar">1º</span>'.html_safe
    when 1
      '<span class="flex items-center justify-center w-8 h-8 rounded-full bg-slate-300 text-slate-700 font-bold text-xs shadow-lg shadow-slate-400/50" title="2º Lugar">2º</span>'.html_safe
    when 2
      '<span class="flex items-center justify-center w-8 h-8 rounded-full bg-orange-400 text-orange-900 font-bold text-xs shadow-lg shadow-orange-500/50" title="3º Lugar">3º</span>'.html_safe
    else
      "#{index + 1}°".html_safe
    end
  end

  def status_icon(status)
    {
      'invited'          => '⏳',
      'accepted'         => '✅',
      'pending_deletion' => '⚠️'
    }[status]
  end
end
