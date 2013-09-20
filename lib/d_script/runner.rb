module DScript
  class Runner < Base
    attr_accessor :script, :output, :id, :master_ch, :block

    def name
      @id ||= pub_redis.incr(ch_name('runner')).to_s
      @name ||= ch_name('runner', id)
    end

    def console_ch
      ch_name('console')
    end

    # d_emitter events
    on :started, :register

    # master events
    on :registered, :set_script
    on :next_block, :next_block

    # console events
    on :reload, :reload

    def run(master_ch)
      # init
      @master_ch = master_ch

      on(:done){ |_| stop }

      start

      # finished
      output.puts "processing complete"
      output.close
    end

    def load_script
      load script
    end

    def register
      d_emit(master_ch, event: "register", name: name)
    end

    def ready
      d_emit(master_ch, event: "ready", name: name)
    end

    def set_script(data)
      @script = data["script"]
      load_script

      output_dir = data["output_dir"]
      @output = File.open("#{output_dir}#{name}.txt", 'w')

      ready
    end

    def reload(data)
      output.puts "reloading #{block}"
      load_script
      handle_block
      d_emit(console_ch, event: "reloaded", name: name)
    end

    def next_block(data)
      @block = data
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
