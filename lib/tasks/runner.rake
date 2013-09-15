namespace :d_script do
  task :runner, :name, :script, :output_file do |t, args|
    name = args[:name]
    script = args[:script]
    output_file = args[:output_file]

    puts "d_script:runner started with name=#{name} script=#{script} output_file=#{output_file}"

    load script
    puts "loaded #{script}"
    redis = Redis.new(REDIS_SETTINGS)
    output = File.open(output_file, 'w') if output_file

    master_ch = name + "-master"
    redis.publish(master_ch, "ready")

    runner_ch = name + "-" + runner_name
    redis.subscribe(runner_ch) do |on|
      on.subscribe do |ch, subscriptions|
        puts "subscribed to ##{ch} (#{subscriptions} subscriptions)"
      end
      on.unsubscribe do |ch, subscriptions|
        puts "unsubscribed to ##{ch} (#{subscriptions} subscriptions)"
      end

      on.message do |ch, msg|
        return redis.unsubscribe(runner_ch) if msg == "done"
        handle_msg(data)
        redis.publish(master_ch, "ready")
      end
    end

    def handle_msg(data)
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
  end
end
