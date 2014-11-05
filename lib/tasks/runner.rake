namespace :d_script do
  task :runner, [ :name, :redis_url ] => [ :environment ] do |t, args|
    name = args[:name]
    redis_url = args[:redis_url]

    puts "d_script:runner started with name=#{name} redis_url=#{redis_url}"

    runner = DScript::Runner.new(name, url: redis_url)
    runner.run
  end
end
