class Impediment < Task
  unloadable

  acts_as_list :scope => :project

  after_save :update_blocks_list

  safe_attributes "blocks", #change to blocks_ids once ui can be manipulated
                  :if => lambda {|impediment, user|
                            (impediment.new_record? && user.allowed_to?(:create_impediments, impediment.project)) ||
                            user.allowed_to?(:update_impediments, impediment.project)
                          }

  def self.find(*args)
    if args[1] && args[1][:conditions]
      if args[1][:conditions].is_a?(Hash)
        args[1][:conditions][:parent_id] = nil
        args[1][:conditions][:tracker_id] = self.tracker
      elsif args[1][:conditions].is_a?(Array)
        args[1][:conditions][0] += " AND parent_id is NULL AND tracker_id = #{self.tracker}"
      end
    else
      args << {:conditions => {:parent_id => nil, :tracker_id => self.tracker}}
    end

    super
  end

  def self.find_all_updated_since(since, project_id)
    super(since, project_id, true)
  end

  def blocks=(ids)
    self.blocks_ids = ids
  end

  def blocks_ids=(ids)
    @blocks_ids_list = [ids] if ids.is_a?(Integer)
    @blocks_ids_list = ids.split(/\D+/).map{|id| id.to_i} if ids.is_a?(String)
    @blocks_ids_list = ids.map {|id| id.to_i} if ids.is_a?(Array)
  end

  def blocks_ids
    @blocks_ids_list ||= relations_from.select{ |rel| rel.relation_type == IssueRelation::TYPE_BLOCKS }.collect(&:issue_to_id)
  end

  def update_with_relationships(params)
    attribs = params.reject { |k, v| !safe_attribute_names.include?(k.to_s) }

    attribs[:remaining_hours] = 0 if IssueStatus.find(params[:status_id]).is_closed?

    result = journalized_update_attributes(attribs)

    move_after params[:prev] if result

    result
  end

  def move_after(prev_id)
    # remove so the potential 'prev' has a correct position
    remove_from_list

    begin
      prev = self.class.find(prev_id)
    rescue ActiveRecord::RecordNotFound
      prev = nil
    end

    # if it's the first story, move it to the 1st position
    if prev.blank?
      insert_at
      move_to_top

    # if its predecessor has no position (shouldn't happen), make it
    # the last story
    elsif !prev.in_list?
      insert_at
      move_to_bottom

    # there's a valid predecessor
    else
      insert_at(prev.position + 1)
    end
  end

  private

  def update_blocks_list
    relations_from = [] if relations_from.nil?
    remove_from_blocks_list
    add_to_blocks_list
  end

  def remove_from_blocks_list
    self.relations_from.delete(self.relations_from.select{|rel| rel.relation_type == IssueRelation::TYPE_BLOCKS && !blocks_ids.include?(rel.issue_to_id) })
  end

  def add_to_blocks_list
    currently_blocking = relations_from.select{|rel| rel.relation_type == IssueRelation::TYPE_BLOCKS}.collect(&:issue_to_id)

    (self.blocks_ids - currently_blocking).each{ |id|
      self.relations_from.create(:relation_type => IssueRelation::TYPE_BLOCKS, :issue_to => Issue.find(id), :issue_from => self)
    }
  end

  def validate
    validate_blocks_list
  end

  def validate_blocks_list
    errors.add :blocks_ids, :must_block_at_least_one_issue if blocks_ids.size == 0
    errors.add :blocks_ids, :can_only_contain_issues_of_current_sprint if Issue.find(blocks_ids).any?{|i| i.fixed_version != self.fixed_version }
  end
end