module DScript
  class Master < Base
    attr_accessor :script, :output_dir, :start_id, :end_id,
                  :block_size, :current_id, :runners, :start_time

    def name
      ch_name('master')
    end

    def console_ch
      ch_name('console')
    end

    def done?
      current_id >= end_id
    end

    def next_end_id
      self.current_id += block_size
    end

    def next_block
      { event: "next_block", start_id: current_id, end_id: next_end_id }
    end

    # events
    on :register, :register_runner
    on :ready, :runner_ready
    on :status, :print_status

    def run(script:, output_dir:, start_id:, end_id:, block_size:)
      # init
      @script = script
      @output_dir = output_dir
      @start_id = start_id
      @end_id = end_id
      @block_size = block_size
      @current_id = start_id
      @runners = {}
      @start_time = Time.now

      start

      # finished
      puts "total time: #{Time.now - start_time}"
    end

    # on :ready, :runner_ready
    def runner_ready(data)
      runner_ch = data["name"]

      if done?
        unregister_runner(runner_ch)
        res = data.merge(event: "done")
      else
        runners[runner_ch] = Time.now
        res = data.merge(next_block)
      end

      d_emit(runner_ch, res)
    end

    def register_runner(data)
      runner_ch = data["name"]
      puts "##{runner_ch} registered (#{runners.length + 1} runners)"
      d_emit(runner_ch, event: "registered", script: script, output_dir: output_dir)
    end

    def unregister_runner(ch)
      runners.delete(ch)
      puts "##{ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end

    def runners_status
      runners.each_with_object("") do |k, v, status|
        status << "\n#{k} = #{v}"
      end
    end

    def print_status(data)
      status = ""
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      if percent_complete > 0
        prediction = run_time / percent_complete
        status << "percentage: #{percent_complete*100}% finish time: #{start_time + prediction}"
      else
        status << "add runners to start processing ids"
      end
      status << runners_status
      puts status
      d_emit(console_ch, event: "status", status: status)
    end
  end
end
