module DScript
  class Console < Base
    def name
      console_ch
    end

    def run
      on :started do
        next_cmd
      end

      on "status" do |data|
        puts data["status"]
        next_cmd
      end

      on "reloaded" do |data|
        output.puts "reloaded #{data["name"]}"
        next_cmd
      end

      start
    end

    def next_cmd
      # parse cmd
      cmd, id = $stdin.gets.chomp, nil
      if /(\w+) (\d+)/.match(cmd)
        cmd, id = $1, $2
      end

      # handle cmd
      case cmd
      when "status"
        d_emit(master_ch, event: "status")
      when "load_script"
        d_emit(ch_name("runner", id), event: "load_script")
      when "exit"
        stop
      end
    end
  end
end
