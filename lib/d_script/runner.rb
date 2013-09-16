module DScript
  class Runner < Base
    attr_accessor :script, :output

    def name
      @name ||= base_name + '-runner-' + pub_redis.incr(base_name).to_s
    end

    def load_script
      load script
    end

    def ready
      d_emit(master_ch, event: "ready", name: name)
    end

    def run(output_file)
      # init
      @output = File.open(output_file, 'w') if output_file

      on :started do
        d_emit(master_ch, event: "register", name: name)
      end

      on "registered" do |data|
        @script = data["script"]
        load_script
        ready
      end

      on "next_block" do |block|
        handle_block(block)
      end

      on "done" do 
        stop 
      end

      start
    end

    def handle_block(block)
      begin
        if output
          CurrentDScript.run(block["start_id"], block["end_id"], output)
        else
          CurrentDScript.run(block["start_id"], block["end_id"])
        end
        ready
      rescue Exception => e
        puts "error running #{block}"
        puts "#{e.class}: #{e.message}"
        e.backtrace.each {|l| puts l }
        until (eval($stdin.gets.chomp)) ; end
        handle_block(block)
      end
    end
  end
end
