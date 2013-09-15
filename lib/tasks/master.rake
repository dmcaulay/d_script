namespace :d_script do
  task :master, :name, :start_id, :end_id, :block_size do |t, args|
    name = args[:name]
    start_id = args[:start_id].to_i
    end_id = args[:end_id].to_i
    block_size = args[:block_size].to_i

    puts "d_script:master started with name=#{name} start_id=#{start_id} end_id=#{end_id} block_size=#{block_size}"

    redis = Redis.new(REDIS_SETTINGS)
    current_id = start_id
    runners = {}
    start_time = Time.now

    redis.subscribe(name + "-master") do |on|
      on.subscribe do |ch, subscriptions|
        puts "subscribed to ##{ch} (#{subscriptions} subscriptions)"
      end
      on.unsubscribe do |ch, subscriptions|
        puts "unsubscribed to ##{ch} (#{subscriptions} subscriptions)"
      end

      on.message do |ch, msg|
        return print_status if msg == "status"
        data = JSON.parse(msg)
        runner_ch = name + "-" + data["name"]
        runners[runner_ch] = Time.now
        if done?
          redis.publish(runner_ch, "done")
        else
          redis.publish(runner_ch, next_block)
        end
      end
    end

    def print_status
      runners.each do |k, v|
        percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
        run_time = Time.now - start_time
        prediction = run_time / percent_complete
        remaining = prediction - run_time
        puts "finish time: #{Time.now + remaining}"
        puts "#{k} = #{v}"
      end
    end

    def done?
      current_id >= end_id
    end

    def next_block
      { start_id: current_id, end_id: next_end_id }.to_json
    end

    def next_end_id
      current_id += block_size
    end
  end
end

