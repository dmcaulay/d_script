module DScript
  class Runner < Base
    attr_accessor :script, :output, :id, :slave_ch, :block

    def name
      @id = pub_redis.incr(runner_ch).to_s
      @name ||= ch_name('runner', id)
    end

    # d_emitter events
    on :started, :register

    # slave events
    on :registered, :set_script
    on :next_block, :next_block
    on :done, :stop

    # console events
    on :reload, :reload

    def run(slave_ch)
      # init
      @output = File.open("#{name}-#{id}.txt", 'w')
      @slave_ch = slave_ch

      start

      # finished
      output.puts "processing complete"
    end

    def load_script
      load script
    end

    def register
      d_emit(slave_ch, event: "register", name: name)
    end

    def set_script(data)
      @script = data["script"]
      load_script
      ready
    end

    def ready
      d_emit(slave_ch, event: "ready", name: name)
    end

    def reload
      output.puts "reloading #{block}"
      load_script
      handle_block
      d_emit(console_ch, event: "reloaded", name: name)
    end

    def next_block
      block = next_block
      output.puts "processing #{block}"
      handle_block
    end

    def handle_block
      begin
        CurrentDScript.run(block["start_id"], block["end_id"], output)
        output.puts "finished #{block}"
        ready
      rescue Exception => e
        output.puts "error running #{block}"
        output.puts "#{e.class}: #{e.message}"
        e.backtrace.each {|l| output.puts l }
      ensure
        output.flush
      end
    end
  end
end
