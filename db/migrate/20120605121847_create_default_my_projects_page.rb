class CreateDefaultMyProjectsPage < ActiveRecord::Migration
  def self.up
    # creates a default my project page config for each project
    # that pretty much mirrors the contents of the static page
    # if there is already a my project page then don't create a second one
    Project.all.each do |project|
      unless MyProjectsOverview.exists? :project_id => project.id
        MyProjectsOverview.create :project => project
      end
    end
  end

  def self.down
    MyProjectsOverview.destroy_all
  end
end
