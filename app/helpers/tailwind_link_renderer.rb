require "will_paginate/view_helpers/action_view"

class TailwindLinkRenderer < WillPaginate::ActionView::LinkRenderer
  def container_attributes
    { class: "join shadow-sm rounded-box bg-base-100 border border-base-200" }
  end

  def page_number(page)
    if page == current_page
      tag(:button, page, class: 'join-item btn btn-primary font-black text-white pointer-events-none')
    else
      link(page, page, class: 'join-item btn btn-ghost hover:btn-primary', rel: rel_value(page))
    end
  end

  def gap
    text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
    %(<button class="join-item btn btn-disabled font-black">#{text}</button>)
  end

  def previous_or_next_page(page, text, classname)
    if page
      link(text, page, class: "join-item btn btn-ghost hover:btn-primary font-bold")
    else
      tag(:button, text, class: "join-item btn btn-disabled font-bold")
    end
  end
end
