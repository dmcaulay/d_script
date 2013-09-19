module DScript
  class Slave < Base
    attr_accessor :script, :runners, :num_runners, :env

    def name
      @id = pub_redis.incr(slave_ch).to_s
      @name ||= slave_ch(id)
    end

    def done?
      @done || num_runners < runners.length
    end

    # master events
    on :started, :register
    on :registered, :set_script
    on :next_block, :next_block
    on :done, :master_done

    # runner events
    on :register, :register_runner
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

    def set_script
      @script = data["script"]
      start_runners
    end

    def start_runners
      num_to_start = num_runners - runners.length
      if num_to_start > 0
        Range.new(1, num_to_start) do
          spawn("RAILS_ENV=#{env} bundle exec rake 'd_script:runner[#{base_name}]'"
        end
      end
    end

    def next_block(data)
      runner_ch = data["runner_ch"]
      d_emit(runner_ch, next_block)
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

    def runner_ready(data)
      runner_ch = data["name"]

      if done?
        unregister_runner(runner_ch)
        d_emit(runner_ch, { event: "done" })
      else
        runners[runner_ch] = Time.now
        ready(runner_ch)
      end
    end

    def register_runner(data)
      runner_ch = data["name"]
      puts "##{runner_ch} subscribed (#{runners.length + 1} runners)"
      d_emit(runner_ch, event: "registered", script: script)
    end

    def unregister_runner(ch)
      runners.delete(ch)
      puts "##{ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end

    def set_num_runners(data)
      num_runners = data["num_runners"]
      start_runners
    end

    def print_status
      status = ""
      runners.each do |k, v|
        status << "\n#{k} = #{v}"
      end
      status = "no registered runners" if status.empty?
      puts status
      d_emit(console_ch, event: "status", status: status)
    end
  end
end
