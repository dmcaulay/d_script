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

    def print_status(start_id, end_id, current_id, start_time)
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      prediction = run_time / percent_complete
      puts "finish time: #{start_time + remaining}"
      runners.each do |k, v|
        puts "#{k} = #{v}"
      end
    end

    def get_block(start_id, end_id)
      { start_id: start_id, end_id: end_id }.to_json
    end

    redis.subscribe(name + "-master") do |on|
      on.subscribe do |ch, subscriptions|
        puts "subscribed to ##{ch} (#{subscriptions} subscriptions)"
      end
      on.unsubscribe do |ch, subscriptions|
        puts "unsubscribed to ##{ch} (#{subscriptions} subscriptions)"
      end

      on.message do |ch, msg|
        # status msg
        return print_status(start_id, end_id, current_id, start_time) if msg == "status"

        # ready msg
        data = JSON.parse(msg)
        runner_ch = name + "-" + data["name"]
        runners[runner_ch] = Time.now
        if current_id >= end_id # done?
          redis.publish(runner_ch, "done")
        else
          block = get_block(current_id, current_id += block_size)
          redis.publish(runner_ch, block)
        end
      end
    end

    puts "done"
  end
end

