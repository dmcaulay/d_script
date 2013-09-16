require "d_emitter"

module DScript
  class Status
    include DEmitter

    # d_emitter
    attr_accessor :name, :pub_redis

    def initialize(name, settings)
      @name = name + '-status'
      @pub_redis = Redis.new(settings)
    end

    def run
      on :started do
        d_emit(@name, event: "status")
      end

      on "status" do |data|
        puts data["status"]
        stop
      end

      start
    end
  end
end
