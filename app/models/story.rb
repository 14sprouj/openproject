class Story < Issue
  unloadable

  def self.condition(project_id, sprint_id, extras=[])
    c = ["project_id = ? AND tracker_id in (?) AND fixed_version_id = ?",
          project_id, Story.trackers, sprint_id]

    if extras.size > 0
      c[0] += ' ' + extras.shift
      c += extras
    end

    c
  end

  # This forces NULLS-LAST ordering
  ORDER = 'CASE WHEN issues.position IS NULL THEN 1 ELSE 0 END ASC, CASE WHEN issues.position IS NULL THEN issues.id ELSE issues.position END ASC'

  def self.backlog(project_id, sprint_id, options={})
    stories = []

    Story.find(:all,
               :order => Story::ORDER,
               :conditions => Story.condition(project_id, sprint_id),
               :joins => :status,
               :limit => options[:limit]).each_with_index {|story, i|
                      next if story.ancestors.any? {|ancestor| ancestor.is_task? }
                      story.rank = i + 1
                      stories << story
                    }

    stories
  end

  def self.product_backlog(project, limit=nil)
    Story.backlog(project.id, nil, :limit => limit)
  end

  def self.sprint_backlog(project, sprint, options={})
    Story.backlog(project.id, sprint.id, options)
  end

  def self.create_and_position(params, safer_attributes)
    Story.new.tap do |s|
      s.safe_attributes = params
      s.author  = safer_attributes[:author]  if safer_attributes[:author]
      s.project = safer_attributes[:project] if safer_attributes[:project]

      if s.save
        s.move_after(params['prev_id'])
      end
    end
  end

  def self.at_rank(project_id, sprint_id, rank)
    return Story.find(:first,
                      :order => Story::ORDER,
                      :conditions => Story.condition(project_id, sprint_id),
                      :joins => :status,
                      :limit => 1,
                      :offset => rank - 1)
  end

  def self.trackers
    trackers = Setting.plugin_backlogs["story_trackers"]
    return [] if trackers.blank?

    trackers.map { |tracker| Integer(tracker) }
  end

  def tasks
    Task.tasks_for(self.id)
  end

  def tasks_and_subtasks
    return [] unless Task.tracker
    self.descendants.find_all_by_tracker_id(Task.tracker)
  end

  def direct_tasks_and_subtasks
    return [] unless Task.tracker
    self.children.find_all_by_tracker_id(Task.tracker).collect { |t| [t] + t.descendants }.flatten
  end

  def set_points(p)
    self.init_journal(User.current)

    if p.blank? || p == '-'
      self.update_attribute(:story_points, nil)
      return
    end

    if p.downcase == 's'
      self.update_attribute(:story_points, 0)
      return
    end

    p = Integer(p)
    if p >= 0
      self.update_attribute(:story_points, p)
      return
    end
  end

  # TODO: Refactor and add tests
  #
  # groups = tasks.partion(&:closed?)
  # {:open => tasks.last.size, :closed => tasks.first.size}
  #
  def task_status
    closed = 0
    open = 0

    self.tasks.each do |task|
      if task.closed?
        closed += 1
      else
        open += 1
      end
    end

    {:open => open, :closed => closed}
  end

  def update_and_position!(params)
    self.safe_attributes = params

    save.tap do |result|
      if result and params[:prev]
        reload
        move_after(params[:prev])
      end
    end
  end

  def rank=(r)
    @rank = r
  end

  def rank
    if self.position.blank?
      extras = ['and ((issues.position is NULL and issues.id <= ?) or not issues.position is NULL)', self.id]
    else
      extras = ['and not issues.position is NULL and issues.position <= ?', self.position]
    end

    @rank ||= Issue.count(:conditions => Story.condition(self.project.id, self.fixed_version_id, extras), :joins => :status)

    return @rank
  end
end
