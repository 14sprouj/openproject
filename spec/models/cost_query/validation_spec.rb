#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe CostQuery::Validation do
  class CostQuery::SomeBase
    include CostQuery::Validation
  end

  it "should be valid with no validations whatsoever" do
    obj = CostQuery::SomeBase.new
    obj.validate("foo").should be_true
    obj.validations.size.should == 0
  end

  it "should allow for multiple validations" do
    obj = CostQuery::SomeBase.new
    obj.register_validations([:integers, :dates])
    obj.validations.size.should == 2
  end

  it "should have errors set when we try to validate something invalid" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    obj.validate("this ain't a number, right?").should be_false
    obj.errors[:int].size.should == 1
  end

  it "should have no errors set when we try to validate something valid" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    obj.validate(1,2,3,4).should be_true
    obj.errors[:int].size.should == 0
  end

  it "should validate integers correctly" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:integers)
    obj.validate(1,2,3,4).should be_true
    obj.errors[:int].size.should == 0
    obj.validate("I ain't gonna work on Maggies Farm no more").should be_false
    obj.errors[:int].size.should == 1
    obj.validate("You've got the touch!", "You've got the power!").should be_false
    obj.errors[:int].size.should == 2
    obj.validate(1, "This is a good burger").should be_false
    obj.errors[:int].size.should == 1
  end

  it "should validate dates correctly" do
    obj = CostQuery::SomeBase.new
    obj.register_validation(:dates)
    obj.validate("2010-04-15").should be_true
    obj.errors[:date].size.should == 0
    obj.validate("2010-15-15").should be_false
    obj.errors[:date].size.should == 1
    obj.validate("2010-04-31").should be_false
    obj.errors[:date].size.should == 1
  end

end
