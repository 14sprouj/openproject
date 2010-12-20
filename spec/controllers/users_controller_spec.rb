require File.dirname(__FILE__) + '/../spec_helper'

describe UsersController do
  before(:each) do
    @controller.stub!(:require_admin).and_return(true)
    @global_roles = [mock_model(GlobalRole), mock_model(GlobalRole)]
    GlobalRole.stub!(:all).and_return(@global_roles)
    User.stub!(:find).with("1").and_return(mock_model User)
  end

  describe "get" do
    before :each do
      @params = {"id" => "1"}
    end

    describe :edit do
      before :each do

      end

      describe "SUCCESS" do
        before :each do

        end

        describe "html" do
          before :each do
            get "edit", @params
          end

          it { response.should be_success }
          it { assigns(:global_roles).should eql @global_roles }
        end
      end

    end

  end
end