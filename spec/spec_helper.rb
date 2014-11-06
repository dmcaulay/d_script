require "d_script"

ENV["D_SCRIPT_ENV"] = "test"

RSpec.configure do |c|
  c.order = :random
end
