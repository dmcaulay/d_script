require 'spec_helper'

describe DScript::EventEmitter do
  let(:emitter) { Emitter.new }
  before(:each) do
    @called = false
    emitter.on(:test_ev) { @called = true }
  end

  describe "#on" do
    it "calls the method on emit" do
      emitter.emit(:test_ev)
      @called.should be_true
    end
  end

  describe "#emit" do
    it "accepts data" do
      emitter.on(:with_data) { |data| @called_sym = data }
      emitter.on("with_data") { |data| @called_s = data }
      emitter.emit(:with_data, "test-data")
      @called_sym.should == "test-data"
      @called_s.should == "test-data"
    end
  end

  describe "on" do
    it "allows you to call class events" do
      emitter.emit(:class_ev)
      emitter.called_class_ev.should be_true
    end
  end

  class Emitter
    include DScript::EventEmitter

    attr_accessor :called_class_ev

    on :class_ev, :class_ev

    def class_ev
      @called_class_ev = true
    end
  end
end
