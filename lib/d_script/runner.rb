module DScript
  class Runner < Base
    attr_accessor :script, :output, :id, :slave_ch, :block

    def name
      @id = pub_redis.incr(runner_ch).to_s
      @name ||= ch_name('runner', id)
    end

    def load_script
      load script
    end

    def ready
      d_emit(slave_ch, event: "ready", name: name)
    end

    def run(slave_ch)
      # init
      @output = File.open("#{name}-#{id}.txt", 'w')
      @slave_ch = slave_ch

      on :started do
        d_emit(slave_ch, event: "register", name: name)
      end

      on "registered" do |data|
        @script = data["script"]
        load_script
        ready
      end

      on "next_block" do |next_block|
        block = next_block
        output.puts "processing #{block}"
        handle_block
      end

      on "load_script" do
        d_emit(console_ch, event: "reloaded", name: name)
        output.puts "restarting #{block}"
        handle_block
      end

      on "done" do
        stop
      end

      start

      output.puts "processing complete"
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
