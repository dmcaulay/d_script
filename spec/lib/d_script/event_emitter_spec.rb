require 'spec_helper'

RSpec.describe DScript::EventEmitter do
  let(:emitter) { Emitter.new }

  it "emits data to the subscribers" do
    emitter.emit(:test_ev, "test-data")
    expect(emitter.data_1).to eql("test-data")
    expect(emitter.data_2).to eql("test-data")
    emitter.emit("test_ev", "test-string")
    expect(emitter.data_1).to eql("test-string")
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
