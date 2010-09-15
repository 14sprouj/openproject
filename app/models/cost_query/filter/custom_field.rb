module CostQuery::Filter
  class CustomField < Base
    extend CostQuery::CustomFieldMixin

    on_prepare do
      # redmine internals just suck
      case custom_field.field_format
      when 'string', 'text' then use :string_operators
      when 'list'           then use :null_operators
      when 'date'           then use :time_operators
      when 'int', 'float'   then use :integer_operators
      when 'bool'
        @possible_values = [['true', 1], ['false', 0]]
        use :null_operators
      else
        fail "cannot handle #{custom_field.field_format.inspect}"
      end
    end

    def self.available_values(*)
      @possible_values || custom_field.possible_values
    end
  end
end
