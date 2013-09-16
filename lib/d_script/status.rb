module DScript
  class Status < Base
    def name
      @base_name + '-status'
    end

    def run
      on :started do
        d_emit(master_ch, event: "status")
      end

      on "status" do |data|
        puts data["status"]
        stop
      end

      start
    end
  end
end
