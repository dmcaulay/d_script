
module DScript
  module EventEmitter
    def count
      events.length
    end

    def on(event, &block)
      events[event] = block
    end

    def emit(event, data = nil)
      if events[event]
        if data
          events[event].call(data)
        else
          events[event].call
        end
      end
    end

    def remove(event)
      events.delete(event)
    end
  end
end
