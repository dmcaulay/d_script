namespace :d_script do
  task :master, [ :name, :script, :start_id, :end_id, :block_size ] => [ :environment ] do |t, args|
    name = args[:name]
    script = args[:script]
    start_id = args[:start_id].to_i
    end_id = args[:end_id].to_i
    block_size = args[:block_size].to_i

    puts "d_script:master started with name=#{name} script=#{script} start_id=#{start_id} end_id=#{end_id} block_size=#{block_size}"

    runner = DScript::Master.new(name, REDIS_SETTINGS)
    runner.run(script, start_id, end_id, block_size)

    puts "done"
  end
end

