require_dependency "users_controller"

module OpenProject::GlobalRoles::Patches
  module UsersControllerPatch
    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)

      base.class_eval do

        before_filter :add_global_roles, :only => [:edit]
      end
    end

    module InstanceMethods
      private
      def add_global_roles
        @global_roles = GlobalRole.all
      end
    end
  end
end

UsersController.send(:include, OpenProject::GlobalRoles::Patches::UsersControllerPatch)
