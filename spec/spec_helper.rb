require "d_script"

ENV["D_SCRIPT_ENV"] ||= "test"

RSpec.configure do |c|
  c.order = :random
  c.before(:suite) do
    log_folder = File.join(File.dirname(__FILE__), 'd_script', 'logs')
    puts "Creating #{log_folder}"
    FileUtils.mkdir_p(log_folder)
  end
end
