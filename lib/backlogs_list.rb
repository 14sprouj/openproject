module Backlogs
  module List
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        # The leading and trailing quotes trick the eval code in acts_as_list.
        # This way, we are able to execute actual code in our quote string. Also
        # sanitize_sql seems to be unavailable in a sensible way. Therefore
        # we're using send to circumvent visibility issues.
        acts_as_list :scope => <<-SCOPE
          " + self.class.send(:sanitize_sql, ['project_id = ? AND fixed_version_id = ? AND tracker_id IN (?)',
                                             self.project_id, self.fixed_version_id, self.class.trackers]) + "
        SCOPE
      end
    end

    module InstanceMethods
      def move_after(prev_id)
        # remove so the potential 'prev' has a correct position
        remove_from_list
        reload

        prev = self.class.find(prev_id) rescue nil

        # if it's the first story, move it to the 1st position
        if prev.blank?
          insert_at
          move_to_top

        # if its predecessor has no position, create an order on position silently.
        # This can happen when sorting inside a version for the first time after backlogs was activated
        # and there have already been items inside the version at the time of backlogs activation
        elsif !prev.in_list?
          prev_pos = set_default_prev_positions_silently(prev)
          insert_at(prev_pos += 1)

        # there's a valid predecessor
        else
          insert_at(prev.position + 1)
        end
      end

      private
      def set_default_prev_positions_silently(prev)
        stories = self.class.find(:all, :conditions => {:fixed_version_id => self.fixed_version_id, :tracker_id => self.class.trackers})

        self.class.record_timestamps = false #temporarily turn off column updates

        highest_pos = stories.sort_by{|s| s.position ? s.position : 0}.collect(&:position).last
        highest_pos = 0 if highest_pos.nil?

        stories.sort_by { |s| s.id }.each do |story|
          next if story.in_list? || story.id > prev.id || self.id == story.id
          story.insert_at(highest_pos += 1)
        end

        self.class.record_timestamps = true #turning updates back on

        highest_pos
      end
    end
  end
end
