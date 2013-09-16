require 'spec_helper'

describe DScript::EventEmitter do
  let(:emitter) { Emitter.new }
  before(:each) do
    @called = false
    emitter.on(:test_ev) { @called = true }
  end

  describe "on" do
    it "adds an event" do
      emitter.count.should == 1
    end

    it "calls the method on emit" do
      emitter.emit(:test_ev)
      @called.should be_true
    end
  end

  describe "emit" do
    it "accepts data" do
      emitter.on(:with_data) { |data| @called = data }
      emitter.emit(:with_data, "test-data")
      @called.should == "test-data"
    end
  end

  describe "remove" do
    it "removes an event" do
      emitter.remove(:test_ev)
      emitter.count.should == 0
    end

    it "no longer calls the method" do
      emitter.remove(:test_ev)
      emitter.emit(:test_ev)
      @called.should be_false
    end
  end

  class Emitter
    include DScript::EventEmitter
    attr_accessor :events

    def initialize
      @events = {}
    end
  end
end
