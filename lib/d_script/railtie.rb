require 'd_script'
require 'rails'

module DScript
  class Railtie < Rails::Railtie
    railtie_name :d_script

    rake_tasks do
      load 'lib/d_script/tasks/master.rake'
      load 'lib/d_script/tasks/runner.rake'
    end
  end
end
