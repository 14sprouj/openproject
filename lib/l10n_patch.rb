module ActionView::Helpers::NumberHelper
  include GLoc
  
  def number_to_currency_with_l10n(number, options = {})
    options[:delimiter] = l(:currency_delimiter) unless options[:delimiter]
    options[:separator] = l(:currency_separator) unless options[:separator]

    options[:unit] = Setting.plugin_redmine_costs['costs_currency'] unless options[:unit]
    options[:format] = Setting.plugin_redmine_costs['costs_currency_format'] unless options[:format]
    
    number_to_currency_without_l10n(number, options)
  end

  alias_method_chain :number_to_currency, :l10n
end