module Backlogs
  module List
    unloadable

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.send(:extend, ClassMethods)
    end

    module ClassMethods
      def acts_as_backlogs_list(trackers)
        self.class_eval do
          acts_as_list :scope => :project #TODO: consider changing the scope to project, version and tracker
          @trackers = trackers
        end
      end
    end

    module InstanceMethods
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
        stories = self.class.find(:all, :conditions => {:fixed_version_id => self.fixed_version_id, :tracker_id => @trackers})

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