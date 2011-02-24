module Report::Controller
  def self.included(base)
    base.class_eval do
      attr_accessor :report_engine

      include ReportingHelper
      helper ReportingHelper
      helper { def engine; @report_engine; end }

      before_filter :determine_engine
      before_filter :prepare_query, :only => [:index, :create]
      before_filter :find_optional_report, :only => [:index, :show, :update, :delete, :rename]
    end
  end

  ##
  # Render the report. Provides named access to saved reports throught the :report
  # parameter and renders either the complete index or the table only
  def index
    if params[:report] && report = report_engine.find_by_name(params[:report].titleize)
      @query = report.deserialize
    end
    table
  end

  ##
  # Render the table partial, if we are setting filters/groups
  def table
    render :partial => 'table' if set_filter?
  end

  ##
  # Create a new saved query. Returns the redirect url to an XHR or redirects directly
  def create
    @query.name = params[:query_name].present? ? params[:query_name] : ::I18n.t(:label_default)
    @query.is_public = !!params[:query_is_public]
    @query.user_id = current_user_id.to_i
    @query.save!
    if request.xhr? # Update via AJAX - return url for redirect
      render :text => url_for(:action => "show", :id => @query.id)
    else # Redirect to the new record
      redirect_to :action => "show", :id => @query.id
    end
  end

  ##
  # Show a saved record, if found. Raises RecordNotFound if the specified query
  # at :id does not exist
  def show
    if @query
      table
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  ##
  # Delete a saved record, if found. Redirects to index on success, raises a
  # RecordNotFound if the query at :id does not exist
  def delete
    if @query
      @query.destroy
    else
      raise ActiveRecord::RecordNotFound
    end
    redirect_to :action => "index"
  end

  ##
  # Update a record with new query parameters and save it. Redirects to the
  # specified record or renders the updated table on XHR
  def update
    if params[:set_filter].to_i == 1 #save
      old_query = @query
      prepare_query
      old_query.migrate(@query)
      old_query.save!
      @query = old_query
    end
    if request.xhr?
      table
    else
      redirect_to :action => "show", :id => @query.id
    end
  end

  ##
  # Rename a record and update its publicity. Redirects to the updated record or
  # renders the updated name on XHR
  def rename
    @query.name = params[:query_name]
    if params.has_key?(:query_is_public)
      @query.is_public = params[:query_is_public] == 'true'
    end
    @query.save!
    unless request.xhr?
      redirect_to :action => "show", :id => @query.id
    else
      render :text => @query.name
    end
  end

  ##
  # Determine the available values for the specified filter and return them as
  # json
  def values
    dependency = params[:dependency].to_sym
    dependent = params[:dependent]

    query = CostQuery.new
    query.filter(dependency,
      :operator => params[:operators][dependency],
      :values => params[:values][dependency])
    query.column(dependent)
    values = query.result.collect {|r| r.fields[dependent] }
    render :text => values.to_json
  end

  ##
  # Determine the requested engine by constantizing from the :engine parameter
  # Sets @report_engine and @title based on that, and makes the engine available
  # to views and widgets via the #engine method.
  # Raises RecordNotFound on failure
  def determine_engine
    @report_engine = params[:engine].constantize
    @title = "label_#{@report_engine.name.underscore}"
  rescue NameError
    raise ActiveRecord::RecordNotFound, "No engine found - override #determine_engine"
  end

  ##
  # Return the id of the current user, for saving queries. Must be overridden by
  # controllers.
  def current_user_id
    raise NotImplementedError, "#{self.class.name} should have overwritten #current_user_id to return the active user's id"
  end

  ##
  # Determines if the request contains filters to set
  def set_filter? #FIXME: rename to set_query?
    params[:set_filter].to_i == 1
  end

  ##
  # Return the active filters
  def filter_params
    filters = http_filter_parameters if set_filter?
    filters ||= session[report_engine.name.underscore.to_sym].try(:[], :filters)
    filters ||= default_filter_parameters
  end

  ##
  # Return the active group bys
  def group_params
    groups = http_group_parameters if set_filter?
    groups ||= session[report_engine.name.underscore.to_sym].try(:[], :groups)
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

  ##
  # Extract active group bys from the http params
  def http_group_parameters
    if params[:groups]
      rows = params[:groups]["rows"]
      columns = params[:groups]["columns"]
    end
    {:rows => (rows || []), :columns => (columns || [])}
  end

  ##
  # Set a default query to cut down initial load time
  def default_filter_parameters
    { :operators => {}, :values => {} }
  end

  ##
  # Set a default query to cut down initial load time
  def default_group_parameters
    {:columns => [:sector_id], :rows => [:country_id]}
  end

  ##
  # Determines if the query settings should be reset
  def force_default?
    params[:default].to_i == 1
  end

  ##
  # Prepare the query from the request
  def prepare_query
    determine_settings
    @query = build_query(session[report_engine.name.underscore.to_sym][:filters], session[report_engine.name.underscore.to_sym][:groups])
  end

  ##
  # Determine the query settings the current request and save it to
  # the session.
  def determine_settings
    if force_default?
      filters = default_filter_parameters
      groups  = default_group_parameters
      clear_cache
    else
      filters = filter_params
      groups  = group_params
    end
    session[report_engine.name.underscore.to_sym] = {:filters => filters, :groups => groups}
  end

  ##
  # Build the query from the passed hash
  def build_query(filters, groups = {})
    query = report_engine.new
    query.tap do |q|
      filters[:operators].each do |filter, operator|
        q.filter(filter.to_sym,
                 :operator => operator,
                 :values => filters[:values][filter])
      end
    end
    groups[:rows].try(:reverse_each) {|r| query.row(r) }
    groups[:columns].try(:reverse_each) {|c| query.column(c) }
    query
  end

  ##
  # Find a report if :id was passed as parameter.
  # Raises RecordNotFound if an invalid :id was passed.
  def find_optional_report
    if params[:id]
      @query = report_engine.find(params[:id].to_i,
        :conditions => ["(is_public = 1) OR (user_id = ?)", current_user_id])
      if @query
        @query.deserialize
      else
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
