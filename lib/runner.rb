require "d_emitter"

module DScript
  class Runner
    include DEmitter

    # d_emitter
    attr_accessor :events, :name, :pub_redis, :sub_redis, :base_name

    def initialize(name, settings)
      @events = {}
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
      @name = name + '-runner-' + pub_redis.incr(name).to_s
      @base_name = name
    end

    # run
    attr_accessor :script, :output

    def master_ch
      base_name + "-master"
    end

    def load_script
      load script
    end

    def run(script, output_file)
      # init
      @script = script
      @output = File.open(output_file, 'w') if output_file

      load_script

      on "next_block" do |block|
        handle_block(block)
        publish(master_ch, event: "ready", name: @name)
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
      rescue Exception => e
        puts "error running #{block}"
        puts e.inspect
        until (eval(gets.chomp)) ; end
        handle_block(block)
      end
    end
  end
end
