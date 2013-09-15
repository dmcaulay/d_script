require 'd_script'
require 'rails'

module DScript
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/master.rake'
      load 'tasks/runner.rake'
    end
  end
end
