module DScript
  class Console < Base

    on :started, proc do
      next_cmd
    end

    on :status, proc do |data|
      puts data["status"]
      next_cmd
    end

    on :reloaded, proc do |data|
      puts "reloaded #{data["name"]}"
      next_cmd
    end

    on :runners_set, proc do |data|
      puts "#{data["name"]} set runners"
      next_cmd
    end

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
        unless id
          d_emit(ch_name("master"), event: "status")
        else
          d_emit(ch_name("slave", id), event: "status")
        end
      when "reload"
        d_emit(ch_name("runner", id), event: "reload")
      when "num_runners"
        d_emit(ch_name("slave", id), event: "num_runners", num_runners: args.to_i)
      when "exit"
        stop
      else
        puts "unknown cmd #{cmd}"
      end
    end
  end
end
