require "d_emitter"

module DScript
  class Master
    include DEmitter

    # d_emitter
    attr_accessor :events, :name, :pub_redis, :sub_redis

    def initialize(name, settings)
      @events = {}
      @name = name + '-master'
      @pub_redis = Redis.new(settings)
      @sub_redis = Redis.new(settings)
    end

    # run
    attr_accessor :start_id, :end_id, :block_size, :current_id, :runners, :start_time

    def done?
      current_id >= end_id
    end

    def next_end_id
      self.current_id += block_size
    end

    def next_block
      { start_id: current_id, end_id: next_end_id }
    end

    def run(start_id, end_id, block_size)
      # init
      @start_id = start_id
      @end_id = end_id
      @block_size = block_size
      @current_id = start_id
      @runners = {}
      @start_time = Time.now

      on "ready" do |data|
        runner_ch = data["name"]

        if done?
          unsubscribe(runner_ch)
          res = "done"
        else
          subscribe(runner_ch) unless runners[runner_ch]
          runners[runner_ch] = Time.now
          res = next_block
        end

        publish(runner_ch, res)
      end

      start
    end

    def subscribe(runner_ch)
      puts "##{runner_ch} subscribed (#{runners.length + 1} runners)"
    end

    def unsubscribe(runner_ch)
      runners.delete(runner_ch)
      puts "##{runner_ch} unsubscribed (#{runners.length} runners)"
      stop if runners.empty?
    end

    def print_status
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      if percent_complete > 0
        prediction = run_time / percent_complete
        puts "percentage: #{percent_complete*100}% finish time: #{start_time + prediction}"
      else
        puts "add runners to start processing ids"
      end
      runners.each do |k, v|
        puts "#{k} = #{v}"
      end
    end
  end
end
