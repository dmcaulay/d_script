require "d_script/version"

require "base"
require "master"
require "runner"
require "status"

module DScript
  require "d_script/railtie" if defined?(Rails)
end
