require 'spec_helper'

describe DScript::DEmitter do
  let(:settings) do
    { driver: "ruby", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:emitter) { DEmitterTest.new("test", settings) }

  describe "start" do
    it "starts the emitter" do
      called = false
      emitter.on("test-ev") { |data| called = true }
      emitter.on(:started) do
        emitter.d_emit("test", { event: "test-ev" })
        emitter.stop
      end
      emitter.start
      called.should be_true
    end
  end

  class DEmitterTest
    include DScript::EventEmitter
    include DScript::DEmitter

    attr_accessor :name, :pub_redis, :sub_redis

    def initialize(name, settings)
      @name = name
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
    end
  end
end
