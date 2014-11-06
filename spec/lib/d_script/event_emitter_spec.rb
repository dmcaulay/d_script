require 'spec_helper'

describe DScript::EventEmitter do
  let(:emitter) { Emitter.new }

  it "emits data to the subscribers" do
    emitter.emit(:test_ev, "test-data")
    emitter.data_1.should == "test-data"
    emitter.data_2.should == "test-data"
    emitter.emit("test_ev", "test-string")
    emitter.data_1.should == "test-string"
  end

  class Emitter
    include DScript::EventEmitter

    attr_accessor :data_1, :data_2

    on :test_ev, :test_1
    on "test_ev", :test_2

    def test_1(data)
      @data_1 = data
    end

    def test_2(data)
      @data_2 = data
    end
  end
end
