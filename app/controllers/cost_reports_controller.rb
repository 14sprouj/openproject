class CostReportsController < ApplicationController
  before_filter :load_all
  before_filter :find_optional_project, :only => [:index, :drill_down]
  before_filter :generate_query,        :only => [:index, :drill_down]
  before_filter :set_cost_types,        :only => [:index, :drill_down]

  rescue_from Exception do |exception|
    session.delete(:cost_query)
    @custom_errors ||= []
    @custom_errors << l(:error_generic)
    render :layout => !request.xhr?
  end

  helper :reporting
  include ReportingHelper

  def index
    @valid = valid_query?
    if @valid
      if @query.group_bys.empty?
        @table_partial = "cost_entry_table"
      elsif @query.depth_of(:column) + @query.depth_of(:row) == 1
        @table_partial = "simple_cost_report_table"
      else
        if @query.depth_of(:column) == 0 || @query.depth_of(:row) == 0
          @query.depth_of(:column) == 0 ? @query.column(:singleton_value) : @query.row(:singleton_value)
        end
        @table_partial = "cost_report_table"
      end
    end
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
    end
  end

  def drill_down
    redirect_to :action => :index
  end

  def available_values
    filter = filter_class(params[:filter_name].to_s)
    render_404 unless filter
    can_answer = filter.respond_to? :available_values
    @available_values = filter.available_values

    respond_to do |format|
      format.html { can_answer ? render(:layout => !request.xhr?) : "" }
    end
  end

  ##
  # Determines if the request contains filters to set
  def set_filter? #FIXME: rename to set_query?
    params[:set_filter].to_i == 1
  end

  ##
  # Determines if the request sets a unit type
  def set_unit?
    params[:unit]
  end

  ##
  # Find a query to search on and put it in the session
  def filter_params
    filters = http_filter_parameters if set_filter?
    filters ||= session[:cost_query].try(:[], :filters)
    filters ||= default_filter_parameters
  end

  def group_params
    groups = http_group_parameters if set_filter?
    groups ||= session[:cost_query].try(:[], :groups)
    groups ||= default_group_parameters
  end

  ##
  # Extract active filters from the http params
  def http_filter_parameters
    params[:fields] ||= []
    (params[:fields].reject { |f| f.empty? } || []).inject({:operators => {}, :values => {}}) do |hash, field|
      hash[:operators][field.to_sym] = params[:operators][field]
      hash[:values][field.to_sym] = params[:values][field]
      hash
    end
  end

  def http_group_parameters
    if params[:groups]
      rows = params[:groups][:rows]
      columns = params[:groups][:columns]
    end
    {:rows => (rows || []), :columns => (columns || [])}
  end

  ##
  # Set a default query to cut down initial load time
  def default_filter_parameters
    {:operators => {:user_id => "=", :spent_on => ">d"},
    :values => {:user_id => [User.current.id], :spent_on => [30.days.ago.strftime('%Y-%m-%d')]}
    }.tap do |hash|
      if @project
        hash[:operators].merge! :project_id => "="
        hash[:values].merge! :project_id => [@project.id]
      end
    end
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    {:columns => [:week], :rows => []}.tap do |h|
      if @project
        h[:rows] << :issue_id
      else
        h[:rows] << :project_id
      end
    end
  end

  def force_default?
    params[:default].to_i == 1
  end

  ##
  # We apply a project filter, except when we are just applying a brand new query
  def ensure_project_scope!(filters)
    return unless ensure_project_scope?
    if @project
      filters[:operators].merge! :project_id => "="
      filters[:values].merge! :project_id => @project.id.to_s
    else
      filters[:operators].delete :project_id
      filters[:values].delete :project_id
    end
  end

  def ensure_project_scope?
    !(set_filter? or set_unit?)
  end

  ##
  # Build the query from the current request and save it to
  # the session.
  def generate_query
    CostQuery::QueryUtils.cache.clear
    filters = force_default? ? default_filter_parameters : filter_params
    groups  = force_default? ? default_group_parameters  : group_params
    ensure_project_scope! filters

    session[:cost_query] = {:filters => filters, :groups => groups}
    @query = CostQuery.new
    @query.tap do |q|
      filters[:operators].each do |filter, operator|
        q.filter(filter.to_sym,
        :operator => operator,
        :values => filters[:values][filter])
      end
    end
    groups[:rows].reverse_each {|r| @query.row(r) }
    groups[:columns].reverse_each {|c| @query.column(c) }
    @query
  end

  def valid_query?
    return true unless @query
    errornous = @query.filters ? @query.filters.select { |f| !f.valid? } : []
    @custom_errors = errornous.map do |err|
      "Filter #{l(err.label)}: #{err.errors.join(", ")}"
    end
    errornous.empty?
  end

  ##
  # Determine active cost types, the currently selected unit and corresponding cost type
  def set_cost_types
    set_active_cost_types
    set_unit
    set_cost_type
  end

  # Determine the currently active unit from the parameters or session
  #   sets the @unit_id -> this is used in the index for determining the active unit tab
  def set_unit
    @unit_id = params[:unit].try(:to_i) || session[:unit_id].to_i
    @unit_id = 0 unless @cost_types.include? @unit_id
    session[:unit_id] = @unit_id
  end

  # Determine the active cost type, if it is not labor or money, and add a hidden filter to the query
  #   sets the @cost_type -> this is used to select the proper units for display
  def set_cost_type
    if @unit_id != 0
      @query.filter :cost_type_id, :operator => '=', :value => @unit_id.to_s, :display => false
      @cost_type = CostType.find(@unit_id) if @unit_id > 0
    end
  end

  #   set the @cost_types -> this is used to determine which tabs to display
  def set_active_cost_types
    unless @cost_types = session[:cost_query][:filters][:values][:cost_type_id].try(:collect, &:to_i)
      relevant_cost_types = CostType.find(:all, :select => "id", :order => "id ASC").select do |t|
        t.cost_entries.count > 0
      end.collect(&:id)
      @cost_types = [-1, 0, *relevant_cost_types]
    end
  end

  def load_all
    CostQuery::GroupBy.all
    CostQuery::Filter.all
  end

  private
  ## FIXME: Remove this once we moved to Redmine 1.0
  def find_optional_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?

    allowed = User.current.allowed_to?({:controller => params[:controller], :action => params[:action]}, @project, :global => true)
    allowed ? true : deny_access
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
