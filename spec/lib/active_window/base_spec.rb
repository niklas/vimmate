require File.dirname(__FILE__) + '/../../spec_helper'

describe ActiveWindow::Base do

  describe 'inheriting to SomeWindow' do
    before( :each ) do
      class SomeWindow < ActiveWindow::Base
      end
    end

    it "should know the name of the .glade file" do
      SomeWindow.glade_name.should == 'some'
    end

    it "should know where to find .glade file" do
      SomeWindow.glade_path.should =~ %r~interfaces/some.glade$~
    end

    it "should expect a root window in the file" do
      SomeWindow.glade_root_name.should == 'Some'
    end

  end
end
