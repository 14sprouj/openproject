class ActionView::Base
  def render_widget(widget, subject, options = {}, &block)
    i = widget.new(subject)
    if Rails.version.start_with? "3"
      i.config = config
      i._routes = _routes
    else
      i.output_buffer = ""
    end
    i._content_for = @_content_for
    i.controller = controller
    i.render_with_options(options, &block).html_safe
  end
end

if Rails.version.start_with? "2"
  class ::String; def html_safe; self; end; end
end

class Widget < ActionView::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::JavaScriptHelper

  attr_accessor :output_buffer, :controller, :config, :_content_for, :_routes

  extend ProactiveAutoloader

  def l(s)
    ::I18n.t(s.to_sym, :default => s.to_s.humanize)
  end

  def current_language
    ::I18n.locale
  end

  def protect_against_forgery?
    false
  end
end
