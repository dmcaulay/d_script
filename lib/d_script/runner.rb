module DScript
  class Runner < Base
    attr_accessor :script, :output, :master_ch, :_block

    def name
      @_id ||= pub_redis.incr(ch_name('runner')).to_s
      @name ||= ch_name('runner', @_id)
    end

    def master_ch
      ch_name('master')
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

    on :done, :stop

    def run
      start

      # finished
      output.puts "processing complete"
      output.close
    end

    # on :started, :register
    def register(_)
      return if @registered
      @registered = true

      d_emit(master_ch, event: "register", name: name)
    end

    # on :registered, :set_script
    def set_script(data)
      @script = data["script"]
      load_script

      output_dir = data["output_dir"]
      @output = File.open(File.join(output_dir, "#{name}.txt"), 'w')

      ready
    end

    # on :next_block, :next_block
    def next_block(data)
      @_block = data
      output.puts "processing #{_block}"
      handle_block
    end

    def reload(_)
      output.puts "reloading #{_block}"
      load_script
      d_emit(console_ch, event: "reloaded", name: name)
      handle_block
    end

    private

    def load_script
      load script
    end

    def ready
      d_emit(master_ch, event: "ready", name: name)
    end

    def handle_block
      begin
        CurrentDScript.run(_block["start_id"], _block["end_id"], output)
        output.puts "finished #{_block}"
        ready
      rescue Exception => e
        output.puts "error running #{_block}"
        output.puts "#{e.class}: #{e.message}"
        e.backtrace.each {|l| output.puts l }
      ensure
        output.flush
      end
    end
  end
end
