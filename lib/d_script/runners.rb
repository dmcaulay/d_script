module DScript
  class Runners
    attr_accessor :num_runners, :env

    def start(name:, redis_url:, num_runners:, env:)
      num_runners.times do
        puts "starting runner"
        spawn("RAILS_ENV=#{env} bundle exec rake 'd_script:runner[#{name},#{redis_url}]'")
      end
    end
  end
end
