namespace :d_script do
  task :runner, [ :name, :slave_ch ] => [ :environment ] do |t, args|
    name = args[:name]
    slave_ch = args[:name]

    puts "d_script:runner started with name=#{name} slave_ch=#{slave_ch}"

    runner = DScript::Runner.new(name, REDIS_SETTINGS)
    runner.run(slave_ch)
  end
end
