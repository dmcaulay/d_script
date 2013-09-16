module DScript
  class Base
    include DEmitter

    # d_emitter
    attr_accessor :events, :pub_redis, :sub_redis, :base_name

    def initialize(name, settings)
      @events = {}
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
      @base_name = name
    end

    def master_ch
      @base_name + '-master'
    end
  end
end
