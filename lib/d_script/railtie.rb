require 'd_script'
require 'rails'

module DScript
  class Railtie < Rails::Railtie
    railtie_name :d_script

    rake_tasks do
      load 'tasks/runner.rake'
    end
  end
end
