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

    print_status = lambda do
      percent_complete = (current_id.to_f - start_id)/(end_id - start_id)
      run_time = Time.now - start_time
      if percent_complete > 0
        prediction = run_time / percent_complete
        puts "finish time: #{start_time + prediction}"
      else
        puts "add runners to start processing ids"
      end
      runners.each do |k, v|
        puts "#{k} = #{v}"
      end
    end

    next_block = lambda do
      { start_id: current_id, end_id: next_end_id }.to_json
    end

    next_end_id = lambda do
      current_id += block_size
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
        return print_status.call if msg == "status"

        # ready msg
        data = JSON.parse(msg)
        runner_ch = name + "-" + data["name"]
        runners[runner_ch] = Time.now
        if current_id >= end_id # done?
          redis.publish(runner_ch, "done")
        else
          redis.publish(runner_ch, next_block.call)
        end
      end
    end

    puts "done"
  end
end

