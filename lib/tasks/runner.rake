namespace :d_script do
  task :runner, :name, :script, :output_file do |t, args|
    name = args[:name]
    script = args[:script]
    output_file = args[:output_file]

    puts "d_script:runner started with name=#{name} script=#{script} output_file=#{output_file}"

    load_script = lambda { load script }
    load_script.call
    puts "loaded #{script}"
    pub_redis = Redis.new(REDIS_SETTINGS)
    sub_redis = Redis.new(REDIS_SETTINGS)
    output = File.open(output_file, 'w') if output_file
    runner_ch = name + '-runner-' + pub_redis.incr(name).to_s

    master_ch = name + "-master"
    ready_msg = {msg: "ready", name: runner_ch}.to_json
    pub_redis.publish(master_ch, ready_msg)

    handle_msg = lambda do |data|
      begin
        puts "running #{script} with #{data}"
        if output
          CurrentDScript.run(data["start_id"], data["end_id"], output)
        else
          CurrentDScript.run(data["start_id"], data["end_id"])
        end
      rescue Exception => e
        puts "error running #{data}"
        puts e.inspect
        until (eval(gets.chomp)) ; end
        handle_msg(data)
      end
    end

    sub_redis.subscribe(runner_ch) do |on|
      on.subscribe do |ch, subscriptions|
        puts "subscribed to ##{ch} (#{subscriptions} subscriptions)"
      end
      on.unsubscribe do |ch, subscriptions|
        puts "unsubscribed to ##{ch} (#{subscriptions} subscriptions)"
      end

      on.message do |ch, msg|
        if msg == "done"
          sub_redis.unsubscribe(runner_ch)
        else
          handle_msg.call(JSON.parse(msg))
          pub_redis.publish(master_ch, ready_msg)
        end
      end
    end

    puts "done"
  end
end
