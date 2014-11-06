module DScript
  class Console < Base

    on :started, proc { next_cmd }

    on :status, proc { |data| puts data["status"]; next_cmd }

    on :reloaded, proc { |data| puts "reloaded #{data["name"]}"; next_cmd }

    def name
      ch_name('console')
    end

    def run
      start
    end

    def next_cmd
      # parse cmd
      input, id, args = $stdin.gets.chomp, false, false
      if /(\w+) (\d+) (.*)$/.match(input)
        cmd, id, args = $1, $2, $3
      elsif /(\w+) (\d+)$/.match(input)
        cmd, id = $1, $2
      else
        cmd = input
      end

      # handle cmd
      case cmd
      when "status"
        d_emit(ch_name("master"), event: "status")
      when "reload"
        d_emit(ch_name("runner", id), event: "reload")
      when "exit"
        stop
      else
        puts "unknown cmd #{cmd}"
      end
    end
  end
end
