module DScript
  class Master < Base
    attr_accessor :start_id, :end_id, :block_size, :current_id, :slaves, :start_time

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

    def run(script, start_id, end_id, block_size)
      # init
      @start_id = start_id
      @end_id = end_id
      @block_size = block_size
      @current_id = start_id
      @slaves = {}
      @start_time = Time.now

      on "register" do |data|
        slave_ch = data["name"]
        d_emit(slave_ch, event: "registered", script: script)
      end

      on "ready" do |data|
        slave_ch = data["name"]

        if done?
          remove_slave(slave_ch)
          res = data.merge({ event: "done" })
        else
          add_slave(slave_ch) unless slaves[slave_ch]
          slaves[slave_ch] = Time.now
          res = data.merge(next_block)
        end

        d_emit(slave_ch, res)
      end

      on "status" do
        print_status
      end

      start

      puts "total time: #{Time.now - start_time}"
    end

    def add_slave(ch)
      puts "##{ch} subscribed (#{slaves.length + 1} slaves)"
    end

    def remove_slave(ch)
      slaves.delete(ch)
      puts "##{ch} unsubscribed (#{slaves.length} slaves)"
      stop if slaves.empty?
    end

    def print_status
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
