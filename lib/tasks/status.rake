namespace :d_script do
  task :status, :name do |t, args|
    name = args[:name]
    puts "requesting status for #{name}"

    runner = DScript::Status.new(name, REDIS_SETTINGS)
    runner.run

    puts "done"
  end
end
