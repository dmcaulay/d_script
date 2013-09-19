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

      start
    end

    def next_cmd
      cmd = $stdin.gets.chomp
      case cmd
      when "status"
        d_emit(master_ch, event: "status")
      when "exit"
        stop
      end
    end
  end
end
