class Widget::Controls::Delete < Widget::Controls
  def render
    return "" if @query.new_record? or !@options[:can_delete]
    button = link_to content_tag(:span, content_tag(:em, l(:button_delete), :class => "button-icon icon-delete")), "#",
          :class => 'button secondary',
          :id => 'query-icon-delete',
          :title => l(:button_delete)
    popup = content_tag :div, :id => "delete_form", :style => "display:none", :class => "button_form" do
      question = content_tag :p, l(:label_really_delete_question)
      options = content_tag :p do
        delete_button = content_tag :span do
          span = content_tag :em do
            l(:button_delete)
          end
        end
        opt1 =  link_to delete_button, url_for(:action => 'delete', :id => @query.id), :method => :delete, :class => "button apply"
        opt2 = link_to l(:button_cancel), "#", :id => "query-icon-delete-cancel", :class => 'icon icon-cancel'
        opt1 + opt2
      end
      question + options
    end
    write(button + popup)
  end
end
