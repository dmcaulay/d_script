namespace :d_script do
  task :master, :name, :start_id, :end_id, :block_size do |t, args|
    name = args[:name]
    start_id = args[:start_id].to_i
    end_id = args[:end_id].to_i
    block_size = args[:block_size].to_i

    puts "d_script:master started with name=#{name} start_id=#{start_id} end_id=#{end_id} block_size=#{block_size}"

    pub_redis = Redis.new(REDIS_SETTINGS)
    sub_redis = Redis.new(REDIS_SETTINGS)
    current_id = start_id
    runners = {}
    start_time = Time.now

    print_status = lambda do
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

    next_end_id = lambda do
      current_id += block_size
    end

    next_block = lambda do
      { start_id: current_id, end_id: next_end_id.call }.to_json
    end

    done = lambda do
      current_id >= end_id
    end

    subscribe = lambda do |runner_ch|
      puts "##{runner_ch} subscribed (#{runners.length + 1} runners)"
    end

    unsubscribe = lambda do |runner_ch|
      runners.delete(runner_ch)
      puts "##{runner_ch} unsubscribed (#{runners.length} runners)"
      sub_redis.unsubscribe(name + '-master') if runners.empty?
    end

    sub_redis.subscribe(name + "-master") do |on|
      on.subscribe do |ch, subscriptions|
        puts "subscribed to ##{ch}"
      end
      on.unsubscribe do |ch, subscriptions|
        puts "unsubscribed to ##{ch}"
      end

      on.message do |ch, msg|
        if msg == "status"
          # status msg
          print_status.call
        else
          # ready msg
          data = JSON.parse(msg)
          runner_ch = data["name"]

          if done.call
            unsubscribe.call(runner_ch)
            res = "done"
          else
            subscribe.call(runner_ch) unless runners[runner_ch]
            runners[runner_ch] = Time.now
            res = next_block.call
          end

          pub_redis.publish(runner_ch, res)
        end
      end
    end

    puts "done"
  end
end

