namespace :d_script do
  task :status, :name do |t, args|
    name = args[:name]
    puts "requesting status for #{name}"
    redis = Redis.new(REDIS_SETTINGS)
    redis.publish(name + "-master", "status")
  end
end
