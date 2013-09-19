
module DScript
  module EventEmitter
    def events
      @events ||= {}
    end

    def on(event, &block)
      events[event] = block
    end

    def emit(event, data = nil)
      [event.to_s, event.to_sym].each do |ev|
        invoke(events[ev], data) if events[ev]
        invoke(method(class_events[ev]), data) if class_events[ev]
      end
    end

    private

    def invoke(block, data)
      if data
       block.call(data)
      else
        block.call
      end
    end

    def class_events
      self.class.events
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # declare events at class level
    module ClassMethods
      def events
        @events ||= {}
      end

      def on(event, method)
        events[event] = method
      end
    end
  end
end
