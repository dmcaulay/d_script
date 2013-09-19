module DScript
  class Master < Base
    attr_accessor :script, :start_id, :end_id, :block_size, :current_id, :slaves, :start_time

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

    # events
    on :register, :register_slave
    on :ready, :slave_ready
    on :status, :print_status

    def run(script, start_id, end_id, block_size)
      # init
      @script = script
      @start_id = start_id
      @end_id = end_id
      @block_size = block_size
      @current_id = start_id
      @slaves = {}
      @start_time = Time.now

      start

      # finished
      puts "total time: #{Time.now - start_time}"
    end

    def register_slave(data)
      slave_ch = data["name"]
      puts "##{slave_ch} registered (#{slaves.length + 1} slaves)"
      d_emit(slave_ch, event: "registered", script: script)
    end

    def unregister_slave(ch)
      slaves.delete(ch)
      puts "##{ch} unsubscribed (#{slaves.length} slaves)"
      stop if slaves.empty?
    end

    def slave_ready(data)
      slave_ch = data["name"]

      if done?
        unregister_slave(slave_ch)
        res = data.merge({ event: "done" })
      else
        slaves[slave_ch] = Time.now
        res = data.merge(next_block)
      end

      d_emit(slave_ch, res)
    end

    def print_status(data)
      status = ""
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      if percent_complete > 0
        prediction = run_time / percent_complete
        status << "percentage: #{percent_complete*100}% finish time: #{start_time + prediction}"
      else
        status << "add slaves to start processing ids"
      end
      slaves.each do |k, v|
        status << "\n#{k} = #{v}"
      end
      puts status
      d_emit(console_ch, event: "status", status: status)
    end
  end
end
