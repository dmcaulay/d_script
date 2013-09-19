module DScript
  class Slave < Base
    attr_accessor :script, :runners, :num_runners

    def name
      @id = pub_redis.incr(slave_ch).to_s
      @name ||= slave_ch(id)
    end

    def ready
      d_emit(master_ch, event: "ready", name: name)
    end

    def done?
      @done || num_runners < runners.length
    end

    def run(num_runners)
      @runners = {}
      @num_runners = num_runners

      on :started do
        d_emit(master_ch, event: "register", name: name)
      end

      on "registered" do |data|
        @script = data["script"]
        start_runners
      end

      on "register" do |data|
        runner_ch = data["name"]
        d_emit(runner_ch, event: "registered", script: script)
      end

      on "done" do |data|
        runner_ch = data["runner_ch"]
        d_emit(runner_ch, { event: "done" })
        @done = true
      end

      on "ready" do |data|
        runner_ch = data["name"]

        if done?
          remove_runner(runner_ch)
          d_emit(runner_ch, { event: "done" })
        else
          add_runner(runner_ch) unless runners[runner_ch]
          runners[runner_ch] = Time.now
          ready
        end
      end

      on "next_block" do |next_block|
        runner_ch = data["runner_ch"]
        d_emit(runner_ch, next_block)
      end

      start
    end

    def add_runner(ch)
      puts "##{ch} subscribed (#{runners.length + 1} runners)"
    end

    def remove_runner(ch)
      runners.delete(ch)
      puts "##{ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end
  end
end
