module ReportingHelper
  include QueriesHelper

  def l(value)
    return value if value.respond_to? :to_str
    super
  end

  ##
  # For a given CostQuery::Filter filter, return an array of hashes, that contain
  # the partials that should be rendered (:name) for that filter and necessary
  # parameters.
  # @param [CostQuery::Filter] the filter we want to render
  def html_elements(filter)
    return text_elements filter if CostQuery::Operator.string_operators.all? { |o| filter.available_operators.include? o }
    return date_elements filter if CostQuery::Operator.time_operators.all?   { |o| filter.available_operators.include? o }
    object_elements filter
  end

  def object_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :multi_values, :filter_name => filter.underscore_name, :values => filter.available_values(User.current)}]
  end

  def date_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :date, :filter_name => filter.underscore_name}]
  end

  def text_elements(filter)
    [
      {:name => :activate_filter, :filter_name => filter.underscore_name, :label => l(filter.label)},
      {:name => :operators, :filter_name => filter.underscore_name, :operators => filter.available_operators},
      {:name => :text_box, :filter_name => filter.underscore_name}]
  end

  def link_to_project(project)
    link_to project.name, :controller => 'projects', :action => 'show', :id => project
  end

  def mapped(value, klass, default)
    id = value.to_i
    return default if id < 0
    klass.find(id).name
  end

  def label_for(field)
    name = field.to_s.camelcase
    return l(field) unless CostQuery::Filter.const_defined? name
    l(CostQuery::Filter.const_get(name).label)
  end

  def debug_fields(result, prefix = ", ")
    prefix << result.fields.inspect << ", " << result.key.inspect if params[:debug]
  end

  def show_field(key, value)
    @show_row ||= Hash.new { |h,k| h[k] = {}}
    @show_row[key][value] ||= field_representation_map(key, value)
  end

  def field_representation_map(key, value)
    return l(:label_none) if value.blank?
    case key.to_sym
    when :activity_id               then mapped value, Enumeration, "<i>#{l(:caption_material_costs)}</i>"
    when :project_id                then link_to_project Project.find(value.to_i)
    when :user_id, :assigned_to_id  then link_to_user User.find(value.to_i)
    when :tyear, :units             then value
    when :tweek                     then "#{l(:label_week)} ##{value}"
    when :tmonth                    then month_name(value.to_i)
    when :category_id               then IssueCategory.find(value.to_i).name
    when :cost_type_id              then mapped value, CostType, l(:caption_labor)
    when :cost_object_id            then link_to_cost_object CostObject.find(value.to_i)
    when :issue_id                  then link_to_issue Issue.find(value.to_i)
    when :spent_on                  then format_date(value.to_date)
    when :tracker_id                then Tracker.find(value.to_i)
    when :week                      then "#{l(:label_week)} #%s" % value.to_i.modulo(100)
    when :priority_id               then IssuePriority.find(value.to_i).name
    when :fixed_version_id          then Version.find(value.to_i).name
    else value.to_s
    end
  end

  def show_result(row, unit_id = @unit_id)
    case unit_id
    when -1 then l_hours(row.units)
    when 0  then row.real_costs ? number_to_currency(row.real_costs) : '-'
    else
      cost_type = @cost_type || CostType.find(unit_id)
      "#{row.units} #{row.units != 1 ? cost_type.unit_plural : cost_type.unit}"
    end
  end

  def action_for(result, options = {})
    options.merge :controller => result.fields['type'] == 'TimeEntry' ? 'timelog' : 'costlog', :id => result.fields['id'].to_i
  end

  ##
  # For a given row, determine how to render it's contents according to usability and
  # localization rules
  def show_row(row)
    row.render { |k,v| show_field(k,v) }
  end
end