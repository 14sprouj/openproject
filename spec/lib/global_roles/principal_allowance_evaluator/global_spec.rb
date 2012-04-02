require File.dirname(__FILE__) + '/../../../spec_helper'

describe GlobalRoles::PrincipalAllowanceEvaluator::Global do

  let(:klass) { GlobalRoles::PrincipalAllowanceEvaluator::Global }
  let(:user) { Factory.build(:user) }
  let(:filter) { klass.new user }
  let(:member) { Factory.build(:member) }
  let(:principal_role) { Factory.build(:principal_role,
                                       :role => role) }
  let(:principal_role2) { Factory.build(:principal_role) }
  let(:role) { Factory.build(:global_role) }
  let(:project) { Factory.build(:project) }

  describe :granted_for_project? do
    it { filter.granted_for_project?(member, :action, project).should be_false }
  end

  describe :denied_for_project? do
    it { filter.denied_for_project?(member, :action, project).should be_false }
  end

  describe :granted_for_global? do
    describe "WHEN checking a Member" do
      it { filter.granted_for_global?(member, :action, {}).should be_false }
    end

    describe "WHEN checking a PrincipalRole
              WHEN the PrincipalRole has a Role that is allowed the action" do
      before do
        role.permissions = [:action]
      end

      it { filter.granted_for_global?(principal_role, :action, {}).should be_true }
    end

    describe "WHEN checking a PrincipalRole
              WHEN the PrincipalRole has a Role that is not allowed the action" do
      it { filter.granted_for_global?(principal_role, :action, {}).should be_false }
    end
  end

  describe :denied_for_global? do
    it { filter.denied_for_global?(principal_role, :action, {}).should be_false }
  end

  describe :project_granting_candidates do
    it { filter.project_granting_candidates(project).should =~ [] }
  end

  describe :global_granting_candidates do
    describe "WHEN the user has a PrincipalRole assigned" do
      before do
        user.principal_roles = [principal_role]
      end

      it { filter.global_granting_candidates =~ [principal_role] }
    end

    describe "WHEN the user has multiple PrincipalRole assigned" do
      before do
        user.principal_roles = [principal_role, principal_role2]
      end

      it { filter.global_granting_candidates =~ [principal_role, principal_role2] }
    end

    describe "WHEN the user has no PrincipalRoles assigned" do
      it { filter.global_granting_candidates =~ [] }
    end
  end
end

