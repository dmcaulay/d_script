require 'spec_helper'

describe DEmitter do
  let(:settings) do
    { driver: "hiredis", url: "redis://localhost:6379", db: 0, timeout: 5 }
  end
  let(:emitter) { Emitter.new("test", settings) }

  describe "start" do
    it "starts the emitter" do
      called = false
      emitter.on("test-ev") { |data| called = true }
      emitter.on(:started) do
        emitter.publish("test", { event: "test-ev" })
        emitter.stop
      end
      emitter.start
      called.should be_true
    end
  end

  class Emitter
    include DEmitter

    attr_accessor :events, :name, :pub_redis, :sub_redis

    def initialize(name, settings)
      @events = {}
      @name = name
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
    end
  end
end
