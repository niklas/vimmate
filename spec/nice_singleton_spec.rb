require File.dirname(__FILE__) + '/spec_helper'

describe VimMate::NiceSingleton do
  before(:each) do
    class MySingleton
      include VimMate::NiceSingleton

      def hello
        "hello"
      end
    end
  end

  it "should respond to .hello" do
    MySingleton.hello.should == 'hello'
  end

  it "should not respond to .goodbye" do
    lambda do
      MySingleton.goodbye
    end.should raise_error(NoMethodError)
  end
end
