require File.dirname(__FILE__) + '/spec_helper'

describe FilesWindow do
  before(:each) do
    @window = FilesWindow.new
  end
  it "should be a FilesWindow" do
    @window.should be_instance_of(VimMate::FilesWindow)
  end
end
