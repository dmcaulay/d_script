require "json"
require "redis"

module DScript
  class Base
    include EventEmitter

    attr_accessor :base_name, :settings

    def initialize(base_name, settings = {})
      @settings = default_settings.merge(settings)
      @base_name = base_name
    end

    def default_settings
      { url: "redis://localhost:6379", db: 0, timeout: 60 * 60, driver: :ruby }
    end

    def ch_name(name, id = false)
      if id
        "#{base_name}-#{name}-#{id}"
      else
        "#{base_name}-#{name}"
      end
    end

    def start
      begin
        sub_redis.subscribe(name) do |on|
          on.subscribe do |ch, subscriptions|
            self.emit(:started)
          end

          on.unsubscribe do |ch, subscriptions|
            self.emit(:stopped)
          end

          on.message do |ch, msg|
            data = JSON.parse(msg)
            self.emit(data['event'], data)
          end
        end
      rescue => error
        log_error("sub #{name}", error)
        retry
      end
    end

    def stop(_ = nil)
      sub_redis.unsubscribe(name)
    end

    def d_emit(ch, data)
      begin
        publish(ch, data)
      rescue => error
        log_error("pub #{ch}", error)
        retry
      end
    end

    private

    def pub_redis
      @pub_redis ||= Redis.new(settings)
    end

    def sub_redis
      @sub_redis ||= Redis.new(settings)
    end

    def log_error(name, error)
      puts error.inspect
      puts error.backtrace.join("\n")
      puts "#{name} retrying in 5s"
      sleep 5
    end

    def publish(ch, data)
      count = pub_redis.publish(ch, data.to_json)
      raise "no subscribers!" if count < 1
    end
  end
end
