class Widget::Controls::Delete < Widget::Base
  def render
    return "" if @query.new_record?
    button = link_to l(:button_delete), "#",
          :class => 'breadcrumb_icon icon-delete',
          :id => 'query-icon-delete',
          :title => l(:button_delete)
    popup = content_tag :div, :id => "delete_form", :class => "button_form" do
      question = content_tag :p, l(:label_really_delete_question)
      options = content_tag :p do
        opt1 = link_to l(:button_delete), url_for(:action => 'delete', :id => @query.id)
        opt2 = link_to l(:button_cancel), "#", :id => "query-icon-delete-cancel", :class => 'icon icon-cancel'
        opt1 + opt2
      end
      question + options
    end
    button + popup
  end
end
