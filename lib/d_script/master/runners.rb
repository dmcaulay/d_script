module DScript
  module Runners
    include EventEmitter

    def self.included(base)
      base.on(:register, :register_runner)
    end

    def register_runner(data)
      runner_ch = data["name"]
      puts "##{runner_ch} registered (#{runners.length + 1} runners)"
      d_emit(runner_ch, event: "registered", script: script, output_dir: output_dir)
    end

    def unregister_runner(ch)
      runners.delete(ch)
      puts "##{ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end

    def runners_status
      status = ""
      runners.each do |k, v|
        status << "\n#{k} = #{v}"
      end
      status
    end
  end
end
