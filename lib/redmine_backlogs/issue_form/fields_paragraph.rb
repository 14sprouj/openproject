class RedmineBacklogs::IssueForm::FieldsParagraph < RedmineBacklogs::IssueView::FieldsParagraph
  def default_fields
    base_fields = super

    fields = ActiveSupport::OrderedHash.new

    fields[:status]          = status_field || base_fields[:status]
    fields[:assigned_to]     = assigned_to_field || base_fields[:assigned_to]
    fields[:fixed_version]   = fixed_version_field || base_fields[:fixed_version]    
    fields[:empty]           = empty

    fields[:category]        = category_field || base_fields[:category]
    fields[:story_points]    = story_points || base_fields[:story_points]
    fields[:remaining_hours] = remaining_hours || base_fields[:remaining_hours]
    fields[:spent_time]      = base_fields[:spent_time]

    unless @issue.is_story?
      fields.delete(:empty)
      fields.delete(:story_points)
    end
    fields[:fixed_version].label = l('label_backlog')

    fields
  end
  
  private
  
  def story_points
    field_class.new(:story_points) { |t| t.text_field_tag "issue[story_points]", issue.story_points.to_s }
  end

  def remaining_hours
    field_class.new(:remaining_hours) { |t| t.text_field_tag "issue[remaining_hours]", issue.remaining_hours.to_s }
  end
  
  def allowed_statuses
    issue.new_statuses_allowed_to(User.current)
  end
  
  def status_field
    if issue.new_record? || allowed_statuses.any?
      field_class.new(:status) { |t| t.select_tag "issue[status_id]", options_for_select(allowed_statuses.collect {|p| [p.name, p.id]}), :required => true }
    else
      nil
    end
  end
  
  def assigned_to_field
    field_class.new(:assigned_to) { |t| t.select_tag "issue[assigned_to_id]", options_for_select(issue.assignable_users.collect {|m| [m.name, m.id]}), :include_blank => true }
  end
  
  def fixed_version_field
    unless issue.assignable_versions.empty?
      field_class.new(:fixed_version) do |t|
        str = t.select_tag "issue[fixed_version_id]", t.version_options_for_select(issue.assignable_versions, issue.fixed_version), :include_blank => true
        str += t.prompt_to_remote(image_tag('add.png', :style => 'vertical-align: middle;'),
                       l(:label_version_new),
                       'version[name]',
                       {:controller => 'versions', :action => 'create', :project_id => @project},
                       :title => l(:label_version_new), 
                       :tabindex => 200) if t.authorize_for('versions', 'new')
        str
      end
    else
      nil
    end
  end
  
  def category_field
    unless issue.project.issue_categories.empty?
      field_class.new(:category) do |t|
        str = t.select_tag "issue[category_id]", options_for_select(issue.project.issue_categories.collect {|c| [c.name, c.id]}), :include_blank => true
        str += t.prompt_to_remote(t.image_tag('add.png', :style => 'vertical-align: middle;'),
                             l(:label_issue_category_new),
                             'category[name]', 
                             {:controller => 'issue_categories', :action => 'new', :project_id => issue.project},
                             :title => l(:label_issue_category_new), 
                             :tabindex => 199) if t.authorize_for('issue_categories', 'new')
        str
      end
    else
      nil
    end
  end
  
  def empty; ChiliProject::Nissue::EmptyParagraph.new; end

  def field_class; ChiliProject::Nissue::SimpleParagraph; end
end
