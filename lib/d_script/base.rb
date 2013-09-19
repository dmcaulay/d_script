
module DScript
  class Base
    include EventEmitter
    include DEmitter

    # d_emitter
    attr_accessor :pub_redis, :sub_redis, :base_name

    def initialize(name, opts)
      settings = { url: opts[:redis], db: 0, timeout: 0, driver: :ruby}
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
      @base_name = name
    end

    def master_ch
      ch_name('master')
    end

    def console_ch
      ch_name('console')
    end

    def ch_name(name, id = false)
      if id
        "#{base_name}-#{name}-#{id}"
      else
        "#{base_name}-#{name}"
      end
    end
  end
end
