namespace :d_script do
  task :runner, [ :name, :redis_url ] => [ :environment ] do |t, args|
    name = args[:name]
    redis_url = args[:redis_url]

    puts "d_script:runner started with name=#{name} redis_url=#{redis_url}"

    runner = DScript::Runner.new(name, url: redis_url)
    runner.run
  end

  if ENV["D_SCRIPT_ENV"] == "test"
    task :environment do
      require 'd_script'
    end
  end
end
