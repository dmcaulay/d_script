require "d_script/version"
require "event_emitter"

module DScript
  require "d_script/railtie" if defined?(Rails)
end
