require "will_paginate/view_helpers/action_view"
class GrupoPaginationRenderer < WillPaginate::ActionView::LinkRenderer
  def prepare(collection, options, template)
    super
    @labels = options[:labels] || []
  end

  def page_number(page)
    letra = @labels[page - 1]&.last || page

    if page == current_page
      tag(:span, letra, class: 'join-item btn btn-sm btn-primary rounded')
    else
      link(letra, page, class: 'join-item btn btn-sm bg-base-300 hover:bg-white hover:text-black rounded')
    end
  end
end
