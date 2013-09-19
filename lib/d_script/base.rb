require 'd_script/d_emitter'

module DScript
  class Base
    include DEmitter

    # d_emitter
    attr_accessor :events, :pub_redis, :sub_redis, :base_name

    def initialize(name, opts)
      @events = {}
      settings = { url: opts[:redis], db: 0, timeout: 0, driver: :ruby}
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
      @base_name = name
    end

    def master_ch
      base_name + '-master'
    end

    def runner_ch(id)
      base_name + '-runner-' + id
    end

    def console_ch
      base_name + '-console'
    end
  end
end
