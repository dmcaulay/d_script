require 'd_script/master/runners'

module DScript
  class Slave < Base
    include Runners

    attr_accessor :script, :runners, :num_runners, :env

    def name
      @id ||= pub_redis.incr(ch_name('slave')).to_s
      @name ||= ch_name('slave', @id)
    end

    def master_ch
      ch_name('master')
    end

    def console_ch
      ch_name('console')
    end

    def done?
      @done || num_runners < runners.length
    end

    # d_emitter events
    on :started, :register

    # master events
    on :registered, :set_script
    on :next_block, :next_block
    on :done, :master_done

    # runner events
    on :ready, :runner_ready

    # console events
    on :status, :print_status
    on :num_runners, :set_num_runners

    def run(num_runners, env)
      @runners = {}
      @num_runners = num_runners
      @env = env

      start
    end

    def register
      d_emit(master_ch, event: "register", name: name)
    end

    def set_script(data)
      @script = data["script"]
      start_runners
    end

    def start_runners
      num_to_start = num_runners - runners.length
      if num_to_start > 0
        Range.new(1, num_to_start).each do
          puts "starting runner"
          spawn("RAILS_ENV=#{env} bundle exec rake 'd_script:runner[#{base_name},#{name}]'")
        end
      end
    end

    def next_block(data)
      runner_ch = data["runner_ch"]
      d_emit(runner_ch, data)
    end

    def master_done(data)
      runner_ch = data["runner_ch"]
      unregister_runner(runner_ch)
      @done = true
      d_emit(runner_ch, { event: "done" })
    end

    def ready(runner_ch)
      d_emit(master_ch, event: "ready", name: name, runner_ch: runner_ch)
    end

    def done(runner_ch)
      d_emit(runner_ch, event: "done")
    end

    def runner_ready(data)
      runner_ch = data["name"]

      if done?
        unregister_runner(runner_ch)
        done(runner_ch)
      else
        runners[runner_ch] = Time.now
        ready(runner_ch)
      end
    end

    def set_num_runners(data)
      @num_runners = data["num_runners"]
      puts "num runners set #{num_runners}"
      start_runners
    end

    def print_status(data)
      status = runners_status
      status = "no registered runners" if status.empty?
      puts status
      d_emit(console_ch, event: "status", status: status)
    end
  end
end
