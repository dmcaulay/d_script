require "d_emitter"

module DScript
  class Status
    include DEmitter

    # d_emitter
    attr_accessor :events, :name, :pub_redis, :sub_redis

    def initialize(name, settings)
      @events = {}
      @name = name + '-status'
      @master_ch = name + '-status'
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
    end

    def run
      on :started do
        d_emit(@master_ch, event: "status")
      end

      on "status" do |data|
        puts data["status"]
        stop
      end

      start
    end
  end
end
