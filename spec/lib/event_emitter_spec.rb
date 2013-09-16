require 'spec_helper'

describe EventEmitter do
  let(:emitter) { Emitter.new }

  describe "on" do
    it "adds an event" do
      emitter.on(:test_ev) { ; }
      emitter.count.should == 1
    end

    it "calls the method on emit" do
      called = false
      emitter.on(:test_ev) { called = true }
      emitter.emit(:test_ev)
      called.should be_true
    end
  end

  describe "remove" do
    let(:called) { false }
    before(:each) do
      emitter.on(:test_ev) { puts "called" }
    end

    it "removes an event" do
      emitter.remove(:test_ev)
      emitter.count.should == 0
    end

    it "no longer calls the method" do
      emitter.remove(:test_ev)
      emitter.emit(:test_ev)
      called.should be_false
    end
  end

  class Emitter
    include EventEmitter
    attr_accessor :events

    def initialize
      @events = {}
    end
  end
end
