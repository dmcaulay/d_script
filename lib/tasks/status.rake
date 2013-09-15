namespace :d_script do
  task :runner, :name do |t, args|
    name = args[:name]
    redis.publish(name + "-master", "status")
  end
end
