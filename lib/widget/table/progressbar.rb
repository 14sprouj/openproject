class Widget::Table::Progressbar < Widget::Base
  attr_accessor :threshhold

  def render
    @threshhold ||= 500
    size = @query.size
      content_tag :div, :id => "progressbar", :class => "form_controls",
      :"data-query-size" => size do
        if size > @threshhold
          content_tag :div, :id => "progressbar-load-table-question", :class => "form_controls" do
            content = content_tag :span, :id => "progressbar-text", :class => "form_controls" do
              ::I18n.translate(:label_load_query_question, :size => size)
             end

            content += content_tag :p do
              p_content = content_tag :a, :class => "reporting_button button" do
                content_tag :span,
                :id => "progressbar-yes",
                :'data-load' => 'true',
                :class => "form_controls",
                :'data-target' => url_for(:action => 'index', :set_filter => '1', :immediately => true) do
                  content_tag :em do
                    ::I18n.t(:label_yes)
                   end
                 end
               end

              p_content += content_tag :a, :class => "reporting_button button" do
                content_tag :span,
                :id => "progressbar-no",
                :'data-load' => 'false',
                :class => "form_controls" do
                  content_tag :em do
                    ::I18n.t(:label_no)
                   end
                 end
               end
             end
            content
           end
        else
      end
        ## TODO render the table when we don't hit the threshhold
        # render_widget Widget::Table, @query, {
        #   :mapping => {
        #     :show_result => method(:show_result),
        #     :show_row => method(:show_row),
        #     :show_field => method(:show_field),
        #     :debug_fields => method(:debug_fields)
        #   }
        # }
    end
  end
end
