require 'spec_helper'

describe DScript::DEmitter do
  let(:settings) do
    { driver: "hiredis", url: "redis://localhost:6379", db: 0, timeout: 5 }
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
    include DScript::DEmitter

    attr_accessor :events, :name, :pub_redis, :sub_redis

    def initialize(name, settings)
      @events = {}
      @name = name
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
    end
  end
end
