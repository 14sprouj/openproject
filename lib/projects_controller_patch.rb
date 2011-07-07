module ProjectIssueStatus
  module ProjectsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        alias_method_chain :settings, :project_issue_statuses
      end
    end


    module InstanceMethods
      def settings_with_project_issue_statuses
        settings_without_project_issue_statuses
        @issue_statuses = IssueStatus.all
      end

      def project_issue_statuses
        selected_statuses = Array.new

        params[:issue_statuses].each do |issue_status|
          if status = IssueStatus.find(issue_status[:status_id].to_i)
            selected_statuses << status
          end
        end if params[:issue_statuses]
        @project.issue_statuses = selected_statuses
        @project.save!

        flash[:notice] = l(:notice_successful_update)
        redirect_to :action => 'settings', :id => @project, :tab => 'project_issue_statuses'
      end
    end
  end
end

ProjectsController.send(:include, ProjectIssueStatus::ProjectsControllerPatch)