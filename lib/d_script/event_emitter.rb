
module DScript
  module EventEmitter
    def emit(event, data = nil)
      Array(events[event.to_sym]).each do |listener|
        listener.call(self, data)
      end
    end

    private

    def events
      self.class.events
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    # declare events at class level
    module ClassMethods
      def events
        @events ||= Hash.new{|h, k| h[k] = Array.new }
      end

      def on(event, method_or_proc)
        events[event.to_sym] << method_or_proc.to_proc
      end
    end
  end
end
