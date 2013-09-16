require 'd_script/event_emitter'
require 'json'
require 'redis'

module DScript
  module DEmitter
    include EventEmitter

    def start
      sub_redis.subscribe(name) do |ev|
        ev.subscribe do |ch, subscriptions|
          self.emit(:started)
        end
        ev.unsubscribe do |ch, subscriptions|
          self.emit(:stopped)
        end

        ev.message do |ch, msg|
          data = JSON.parse(msg)
          self.emit(data['event'], data)
        end
      end
    end

    def stop
      sub_redis.unsubscribe(name)
    end

    def d_emit(ch, data)
      pub_redis.publish(ch, data.to_json)
    end
  end
end
