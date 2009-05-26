require File.dirname(__FILE__) + '/../spec_helper'

describe FileTreeStore do
  it "should inherit from ActiveWindow::ActiveTreeStore" do
    FileTreeStore.should < ActiveWindow::ActiveTreeStore
  end

  context "new" do
    before( :each ) do
      @tree = FileTreeStore.new
    end

    it "should have an empty exclude list" do
      @tree.excludes.should be_empty
    end

    context "excluding tmp, doc and public dirs" do
      before( :each ) do
        @rules = %w(tmp doc public)
        @rules.each do |rule|
          lambda { @tree.exclude! rule }.should change(@tree.excludes, :count).by(1)
        end
      end

      it "should have stored the rules in excludes" do
        @tree.excludes.should_not be_empty
      end

      it "should ignore paths that end with /$rule" do
        @tree.should be_excludes("foo/tmp")
        @tree.should be_excludes("foo/bar/tmp")
      end

      it "should not ignore that contain $rule somewhere else the end" do
        @tree.should_not be_excludes("foo/tmp/more")
      end
    end
  end
end

