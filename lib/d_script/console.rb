module DScript
  class Console < Base

    on :started, :next_cmd

    on :status, :status_complete

    on :reloaded, :reloaded_complete

    def name
      ch_name('console')
    end

    def run
      start
    end

    def status_complete(data)
      puts data["status"]
      next_cmd
    end

    def reloaded_complete(data)
      puts "reloaded #{data["name"]}"
      next_cmd
    end

    def next_cmd(_ = nil)
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
