module DScript
  class Master < Base
    attr_accessor :start_id, :end_id, :block_size, :current_id, :runners, :start_time

    def name
      master_ch
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

    def run(start_id, end_id, block_size)
      # init
      @start_id = start_id
      @end_id = end_id
      @block_size = block_size
      @current_id = start_id
      @runners = {}
      @start_time = Time.now

      on "ready" do |data|
        runner_ch = data["name"]

        if done?
          remove_runner(runner_ch)
          res = { event: "done" }
        else
          add_runner(runner_ch) unless runners[runner_ch]
          runners[runner_ch] = Time.now
          res = next_block
        end

        d_emit(runner_ch, res)
      end

      on "status" do
        print_status
      end

      start

      puts "total time: #{Time.now - start_time}"
    end

    def add_runner(ch)
      puts "##{ch} subscribed (#{runners.length + 1} runners)"
    end

    def remove_runner(ch)
      runners.delete(ch)
      puts "##{ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end

    def print_status
      status = ""
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      if percent_complete > 0
        prediction = run_time / percent_complete
        status << "percentage: #{percent_complete*100}% finish time: #{start_time + prediction}"
      else
        status << "add runners to start processing ids"
      end
      runners.each do |k, v|
        status << "\n#{k} = #{v}"
      end
      puts status
      d_emit("#{base_name}-status", event: "status", status: status)
    end
  end
end
