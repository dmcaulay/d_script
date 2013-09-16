require "base"

module DScript
  class Runner < Base
    attr_accessor :script, :output

    def name
      @name ||= base_name + '-runner-' + pub_redis.incr(name).to_s
    end

    def load_script
      load script
    end

    def ready
      d_emit(master_ch, event: "ready", name: @name)
    end

    def run(script, output_file)
      # init
      @script = script
      @output = File.open(output_file, 'w') if output_file

      load_script

      on :started do
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
        puts e.inspect
        until (eval(gets.chomp)) ; end
        handle_block(block)
      end
    end
  end
end
