require "d_script/version"
require "event_emitter"
require "d_emitter"

module DScript
  require "d_script/railtie" if defined?(Rails)
end
