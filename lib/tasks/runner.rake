namespace :d_script do
  task :runner, [ :name ] => [ :environment ] do |t, args|
    name = args[:name]

    puts "d_script:runner started with name=#{name}"

    runner = DScript::Runner.new(name, REDIS_SETTINGS)
    runner.run

    puts "done"
  end
end
