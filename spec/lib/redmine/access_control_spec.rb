require File.dirname(__FILE__) + '/../../spec_helper'

describe Redmine::AccessControl do
  let(:view_project_permission) { Redmine::AccessControl.permission(:view_project) }
  let(:edit_project_permission) { Redmine::AccessControl.permission(:edit_project) }

  describe :view_project do
    it { view_project_permission.actions.should be_include("my_projects_overviews/index") }
  end

  describe :edit_project do
    it { edit_project_permission.actions.should be_include("my_projects_overviews/page_layout") }
    it { edit_project_permission.actions.should be_include("my_projects_overviews/add_block") }
    it { edit_project_permission.actions.should be_include("my_projects_overviews/update_custom_element") }
    it { edit_project_permission.actions.should be_include("my_projects_overviews/order_blocks") }
    it { edit_project_permission.actions.should be_include("my_projects_overviews/destroy_attachment") }
  end
end
