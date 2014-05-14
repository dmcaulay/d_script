namespace :d_script do
  task :runner, [ :name, :master_ch ] => [ :environment ] do |t, args|
    name = args[:name]
    master_ch = args[:master_ch]

    puts "d_script:runner started with name=#{name} master_ch=#{master_ch}"

    runner = DScript::Runner.new(name, RedisConfig[:sidekiq])
    runner.run(master_ch)
  end
end
